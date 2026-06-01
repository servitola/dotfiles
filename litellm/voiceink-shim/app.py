# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "fastapi>=0.115",
#   "uvicorn[standard]>=0.32",
#   "python-multipart>=0.0.12",
# ]
# ///
"""OpenAI-compatible /v1/audio/transcriptions shim around the VoiceInk CLI.

VoiceInk.app runs whisper.cpp + Metal on the host and applies the user's
dictionary (vocabulary words + word replacements stored in dictionary.store).
This shim accepts multipart uploads in OpenAI's transcription format, writes
them to a temp file, shells out to the `voiceink` CLI (which IPCs the running
app via DistributedNotificationCenter), and returns the resulting text.

Binds 127.0.0.1:8178 — Docker Desktop routes the LiteLLM container to it via
host.docker.internal:8178, same pattern as the existing Ollama wiring.

VoiceInk.app must be running for transcription to succeed; the CLI auto-launches
it (hidden) if not, but the user runs it always-open so that path is unused.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import PlainTextResponse

VOICEINK_BIN = Path(
    os.environ.get("VOICEINK_BIN", "/usr/local/bin/voiceink")
)
TIMEOUT = int(os.environ.get("VOICEINK_TIMEOUT", "600"))
HOST = os.environ.get("VOICEINK_SHIM_HOST", "127.0.0.1")
PORT = int(os.environ.get("VOICEINK_SHIM_PORT", "8178"))

# CLI returns plain text via stdout — no segments, no timestamps, no word-level
# data. srt/vtt require real timestamps and would be lies; verbose_json is the
# OpenAI default LiteLLM uses upstream (it rewrites callers' response_format
# to verbose_json for its own bookkeeping), so we must serve it with the
# documented shape but empty segments / unknown language.
UNSUPPORTED_FORMATS = {"srt", "vtt"}

app = FastAPI(title="VoiceInk shim", version="0.1.0")


@app.get("/health")
def health() -> dict:
    return {"ok": VOICEINK_BIN.exists(), "bin": str(VOICEINK_BIN)}


@app.post("/v1/audio/transcriptions")
async def transcriptions(
    file: UploadFile = File(...),
    model: str | None = Form(None),
    prompt: str | None = Form(None),
    response_format: str = Form("json"),
    temperature: float | None = Form(None),
    language: str | None = Form(None),
):
    if response_format in UNSUPPORTED_FORMATS:
        raise HTTPException(
            400,
            f"response_format='{response_format}' not supported — VoiceInk CLI "
            "returns plain text, no segments/timestamps.",
        )

    # Preserve original extension so whisper.cpp inside VoiceInk picks the
    # right decoder path (it sniffs by extension as well as content).
    suffix = Path(file.filename or "audio.wav").suffix or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name

    try:
        proc = subprocess.run(
            [str(VOICEINK_BIN), "transcribe", tmp_path],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(504, f"voiceink timed out after {TIMEOUT}s")
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass

    if proc.returncode != 0:
        raise HTTPException(
            500, proc.stderr.strip() or "voiceink failed without stderr"
        )

    text = proc.stdout.strip()

    if response_format == "text":
        return PlainTextResponse(text)
    if response_format == "verbose_json":
        # Minimal valid TranscriptionVerbose: empty segments since VoiceInk
        # doesn't expose them; LiteLLM accepts this shape and forwards `text`.
        return {
            "task": "transcribe",
            "language": "unknown",
            "duration": 0.0,
            "text": text,
            "segments": [],
        }
    return {"text": text}


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
