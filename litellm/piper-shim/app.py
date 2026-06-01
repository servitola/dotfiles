# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "fastapi>=0.115",
#   "uvicorn[standard]>=0.32",
# ]
# ///
"""OpenAI-compatible /v1/audio/speech shim around local Piper TTS.

Piper runs inside ~/.venv/tts (Python 3.11) with the Russian voice model at
~/.local/share/piper-voices/ru_RU-irina-medium.onnx.  This shim accepts
OpenAI-format TTS requests, shells out to piper, converts WAV→MP3 via ffmpeg
if the caller requests mp3, and streams the audio bytes back.

The `voice` param from the caller (e.g. "Kore" from serho) is intentionally
ignored — piper only has one Russian voice wired here.

Binds 127.0.0.1:8177.  LiteLLM container reaches it via host.docker.internal:8177,
same pattern as the voiceink-shim on :8178.
"""
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

PIPER_PYTHON = Path(os.environ.get("PIPER_PYTHON", str(Path.home() / ".venv/tts/bin/python")))
PIPER_MODEL = Path(os.environ.get("PIPER_MODEL", str(Path.home() / ".local/share/piper-voices/ru_RU-irina-medium.onnx")))
HOST = os.environ.get("PIPER_SHIM_HOST", "127.0.0.1")
PORT = int(os.environ.get("PIPER_SHIM_PORT", "8177"))
TIMEOUT = int(os.environ.get("PIPER_TIMEOUT", "60"))


app = FastAPI(title="Piper TTS shim", version="0.1.0")


class SpeechRequest(BaseModel):
    model: str = "tts-1"
    input: str
    voice: str = "alloy"
    response_format: str = "mp3"
    speed: float = 1.0


@app.get("/health")
def health() -> dict:
    return {"ok": PIPER_MODEL.exists(), "model": str(PIPER_MODEL)}


@app.post("/v1/audio/speech")
async def speech(req: SpeechRequest) -> Response:
    if not PIPER_PYTHON.exists():
        raise HTTPException(503, f"Piper venv not found: {PIPER_PYTHON}")
    if not PIPER_MODEL.exists():
        raise HTTPException(503, f"Voice model not found: {PIPER_MODEL}")

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = Path(tmp.name)

    try:
        proc = subprocess.run(
            [str(PIPER_PYTHON), "-m", "piper",
             "--model", str(PIPER_MODEL),
             "--output_file", str(wav_path)],
            input=req.input,
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
        )
        if proc.returncode != 0:
            raise HTTPException(500, proc.stderr.strip() or "piper failed")

        if req.response_format == "mp3":
            mp3_path = wav_path.with_suffix(".mp3")
            ff = subprocess.run(
                ["ffmpeg", "-y", "-i", str(wav_path), "-q:a", "4", str(mp3_path)],
                capture_output=True,
                timeout=30,
            )
            if ff.returncode == 0:
                return Response(content=mp3_path.read_bytes(), media_type="audio/mpeg")

        return Response(content=wav_path.read_bytes(), media_type="audio/wav")
    finally:
        wav_path.unlink(missing_ok=True)
        wav_path.with_suffix(".mp3").unlink(missing_ok=True)


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
