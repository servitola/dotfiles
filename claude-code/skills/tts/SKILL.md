---
name: tts
description: |
  Generate speech audio (WAV/MP3) from text via the user's own free TTS
  stack: local LiteLLM proxy (localhost:4000) with Gemini TTS, local Piper
  (Russian), Azure Neural voices.

  Use when: "озвучь текст", "озвучь это", "сделай аудио из текста",
  "сгенерируй речь", "сделай mp3 из текста", "проговори текст", "text to
  speech", "voice this text", "read this aloud", "generate speech".

  Do NOT use for: Greek audio (greek-tts skill) or speech-to-text
  (voiceink-local alias / VoiceInk app).
---

# TTS — text to speech via the local LiteLLM proxy

Everything goes through one endpoint: `POST http://localhost:4000/v1/audio/speech`
with header `Authorization: Bearer sk-local-workbot` (value of
`LITELLM_MASTER_KEY` set in `litellm/docker-compose.yml`). OpenAI-compatible body:
`{"model": "<alias>", "input": "<text>", "voice": "<voice>"}`.

## Pick the backend

| Situation | Alias | Why |
|---|---|---|
| Default — any language, good quality | `tts` | Gemini 2.5 Flash TTS, multilingual incl. Russian, 30 voices (default `Kore`), free 15 RPM |
| Narration / better prosody | `tts-pro` | Gemini 2.5 Pro TTS, same free quota pool, slower |
| Russian, guaranteed/offline/no quota | `tts-piper` | local Piper on `127.0.0.1:8177`, always free, single voice `ru_RU-irina-medium`, Russian only |
| Russian last-resort fallback | `tts-azure-ru` | Azure Neural, voice forced to `ru-RU-DmitryNeural` by a proxy hook |
| Explicit Azure voice (any locale) | `tts-azure` | voice-agnostic; pass a full Azure voice id like `en-US-AriaNeural` |
| Greek | — | stop: invoke the `greek-tts` skill instead (it wraps `tts-azure` with el-GR voices and dialogue handling) |

Fallback: the proxy config declares `tts → tts-piper → tts-azure-ru`, but in
practice router fallbacks do not fire for `/v1/audio/speech` (verified by the
serho bot, which implements the chain client-side). So when a model fails,
retry the next alias yourself: Russian text `tts → tts-piper → tts-azure-ru`;
non-Russian `tts → tts-pro → tts-azure` (piper can't speak it).

## Workflow

1. Health-check before generating: `curl -s http://localhost:4000/health/liveliness`.
   If down: `cd ~/projects/dotfiles/litellm && docker compose up -d`.
2. Run the exact invocation for the chosen alias from
   [backends.md](references/backends.md) — per-backend curl/python commands,
   output formats, voices, quirks (the Gemini `response_format` crash, the
   conversational-text 400), and health checks.
3. Text longer than ~3000 chars (Gemini hard cap 4096/req): split on sentence
   or paragraph boundaries, generate per chunk, concatenate with ffmpeg —
   chunking recipe is in [backends.md](references/backends.md) § Long text.
4. Want a specific delivery (cheerful, whisper, slow, accent)? Apply the
   style-control patterns from [prompting.md](references/prompting.md) —
   Gemini natural-language prefixes, the `speed` param, Azure SSML.

## Output and delivery

- `tts` / `tts-pro` return 24 kHz mono PCM **WAV**. Save as `.wav`; for an mp3
  ask: `ffmpeg -i out.wav -q:a 4 out.mp3`.
- `tts-piper`: always send `"response_format": "mp3"` explicitly → **MP3**;
  any other value (or the field stripped by the proxy) yields WAV.
- `tts-azure` / `tts-azure-ru` return **MP3**.
- Name the file after the content (`/tmp/tts_meeting_summary.mp3`, not `out.mp3`);
  inside a project/topic directory, save there instead of `/tmp`.
- In a Telegram-bot session, ship via `mcp__bot__send_document` (inline player);
  for a voice bubble transcode first: `ffmpeg -i out.wav -c:a libopus -b:a 32k -application voip out.ogg`.
  In a plain CLI session, `afplay out.wav` or `open` the file.
