# TTS backends — exact invocations

All aliases live on the local LiteLLM proxy. Source of truth:
`~/projects/dotfiles/litellm/config.yaml` (TTS blocks) and
`~/projects/dotfiles/litellm/README.md` § TTS.

## Contents
- Common setup and health checks
- tts / tts-pro (Gemini)
- tts-piper (local Piper, Russian)
- tts-azure / tts-azure-ru (Azure Neural)
- Fallback chain (client-side)
- Long text: chunking and concat
- Python invocation
- Failure modes

## Common setup and health checks

```bash
BASE="${LITELLM_BASE:-http://localhost:4000}"
KEY="${LITELLM_MASTER_KEY:-sk-local-workbot}"

curl -s "$BASE/health/liveliness"                       # → "I'm alive!"
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" \
  | jq -r '.data[].id' | grep tts                       # tts tts-pro tts-piper tts-azure tts-azure-ru
curl -s http://127.0.0.1:8177/health                    # piper shim → {"ok":true,"model":".../ru_RU-irina-medium.onnx"}
```

Proxy down → `cd ~/projects/dotfiles/litellm && docker compose up -d`.
Piper shim down → `launchctl load ~/Library/LaunchAgents/com.servitola.piper-shim.plist`;
logs at `~/projects/dotfiles/litellm/piper-shim/logs/launchd.err.log`.

## tts / tts-pro — Gemini 2.5 Flash/Pro TTS

Primary backend. Multilingual (incl. Russian), 30 voices, free 15 RPM /
~1500 RPD, 4096 chars per request. `tts-pro` = better prosody, same quota
pool, slower. Output: 24 kHz mono PCM WAV.

```bash
curl -sS "$BASE/v1/audio/speech" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "tts", "input": "Привет! Это тест синтеза речи.", "voice": "Kore"}' \
  -o /tmp/tts_test.wav
```

Quirks (learned the hard way by the serho bot — `~/projects/serho/src/telegram_bot/core/services/tts.py`):

- Omit `response_format` entirely. The LiteLLM→Gemini bridge misinterprets
  the field and returns HTTP 500. Output is always WAV; transcode with ffmpeg
  if you need mp3/ogg.
- Conversational text (greetings, sentences ending with a question)
  deterministically trips Gemini's safety check: 400 "Model tried to
  generate text…", surfaced by the proxy as HTTP 500. On that error go
  straight to the next backend in the chain.
- `speed` is accepted (OpenAI-standard 0.25–4.0 multiplier; serho uses 1.15).
  Omit for natural rate.

Voices (subset the bot exposes; case-sensitive): `Kore` (default), `Puck`,
`Charon`, `Fenrir`, `Aoede`. Gemini ships ~30 total prebuilt voices.

## tts-piper — local Piper, Russian only

Always available, zero quota, fully offline. FastAPI shim at
`127.0.0.1:8177` (`~/projects/dotfiles/litellm/piper-shim/app.py`, launchd
agent `com.servitola.piper-shim`), Piper venv `~/.venv/tts`, voice model
`~/.local/share/piper-voices/ru_RU-irina-medium.onnx`. The `voice` param is
ignored — one female Russian voice. Non-Russian input comes out garbled, so
route only Russian text here.

Via the proxy (preferred — uniform auth/logging):

```bash
curl -sS "$BASE/v1/audio/speech" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "tts-piper", "input": "Привет, это локальный синтез.", "response_format": "mp3"}' \
  -o /tmp/tts_piper.mp3
```

Direct to the shim (works even when the docker proxy is down):

```bash
curl -sS http://127.0.0.1:8177/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"model": "tts-1", "input": "Привет.", "response_format": "mp3"}' \
  -o /tmp/tts_piper.mp3
```

`response_format`: always send `"mp3"` explicitly → MP3 (shim converts via
ffmpeg); any other value — or the field stripped by the proxy — yields WAV.
(The shim's pydantic default in `piper-shim/app.py` is `"mp3"`, but proxy
forwarding of the field is not guaranteed, so don't rely on the default.)
The shim ignores `speed`.

## tts-azure / tts-azure-ru — Azure Neural

Azure AI Speech resource `tts-greek`, West Europe, F0 free tier (500K
chars/month, recurring). 400+ neural voices, any locale — the resource name
is historical, voices are not region-locked. Output: MP3.

- `tts-azure` — voice-agnostic; you pass a full Azure voice id. Owned by the
  `greek-tts` skill for Greek; fine to use for other locales with an explicit
  voice (e.g. `en-US-AriaNeural`, `de-DE-KatjaNeural`).
- `tts-azure-ru` — same backend; a proxy pre-call hook
  (`litellm/tts_voice_rewriter.py`) force-rewrites `voice` to
  `ru-RU-DmitryNeural`, so Gemini voice names passed during fallback don't
  400. Russian last resort only.

```bash
curl -sS "$BASE/v1/audio/speech" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "tts-azure", "input": "Good evening.", "voice": "en-US-AriaNeural"}' \
  -o /tmp/tts_azure.mp3
```

`input` may be raw SSML for rate/pitch/pause control — see prompting.md and
the working SSML wrapper in `~/projects/dotfiles/litellm/greek-tts.sh`
(it also caches per-utterance MP3s in `~/.cache/greek-tts/`).

## Fallback chain (client-side)

config.yaml declares `fallbacks: tts → tts-piper → tts-azure-ru`, but the
serho bot found router fallbacks do not fire for `/v1/audio/speech`
(`tts_fallback.py`). Implement the chain yourself:

- Russian text: `tts` → `tts-piper` → `tts-azure-ru`
  (conversational Russian — greetings/questions — start with `tts-piper` or
  `tts-azure-ru` to dodge the Gemini 400-as-500)
- Non-Russian: `tts` → `tts-pro` → `tts-azure` (with an explicit locale voice)

Retry logic: 408/429/5xx → next model in the chain; other 4xx → config/auth
problem, fix it instead of retrying.

## Long text: chunking and concat

Gemini caps at 4096 chars/request; stay under ~3000 to be safe (serho caps
at 2000). Split on paragraph/sentence boundaries, synthesize each chunk with
the same model+voice, then concatenate:

```bash
# files.txt: one line per chunk —  file '/tmp/chunk_00.wav'
ffmpeg -y -f concat -safe 0 -i files.txt -c:a libmp3lame -b:a 48k -ar 24000 -ac 1 /tmp/tts_full.mp3
```

For multi-voice dialogues with inter-turn silence, reuse the proven pattern
in `greek-tts.sh` (anullsrc silence + concat list).

## Python invocation

```python
import httpx

def synthesize(text: str, out: str, model: str = "tts", voice: str = "Kore") -> None:
    payload = {"model": model, "input": text, "voice": voice}
    # response_format intentionally absent — Gemini bridge 500s on it
    r = httpx.post(
        "http://localhost:4000/v1/audio/speech",
        headers={"Authorization": "Bearer sk-local-workbot"},
        json=payload,
        timeout=60.0,
    )
    r.raise_for_status()
    with open(out, "wb") as f:
        f.write(r.content)  # WAV for tts/tts-pro, MP3 for azure aliases
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| connection refused on :4000 | proxy down | `cd ~/projects/dotfiles/litellm && docker compose up -d` |
| 401/403 from proxy | key drift | check `LITELLM_MASTER_KEY` vs `sk-local-workbot` in `litellm/docker-compose.yml` |
| 500 from `tts` on chatty text | Gemini "Model tried to generate text" 400 surfaced as 500 | next backend in chain |
| 500 from `tts` with `response_format` set | bridge bug | drop the field, transcode locally |
| 429 from `tts` | Gemini 15 RPM / daily quota | `tts-piper` (ru) or `tts-azure` |
| 503 from piper shim | venv or model missing | check `~/.venv/tts` and `~/.local/share/piper-voices/`, reload launchd agent |
| 429 from azure aliases | F0 500K chars/month spent | wait for monthly reset |
| empty reply from proxy | container starting | `docker compose logs -f litellm` until "Application startup complete" |
