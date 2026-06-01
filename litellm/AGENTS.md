# litellm — agent rules

## Models and providers

- Free models only. After any [config.yaml](config.yaml) edit: `scripts/verify-free-only.sh` must exit 0.
- OpenRouter deployments use `openai/<slug>` + `api_base: https://openrouter.ai/api/v1`. Never `openrouter/<slug>`.
- Groq deployments use native `groq/<slug>` (no `api_base`).
- Z.AI deployments use native `zai/<slug>` (no `api_base`).
- Mistral deployments use native `mistral/<slug>` (no `api_base`).
- Gemini deployments use native `gemini/<slug>` (no `api_base`).
- Cerebras deployments use `openai/<slug>` + `api_base: https://api.cerebras.ai/v1`.
- NVIDIA NIM deployments use `openai/<slug>` + `api_base: https://integrate.api.nvidia.com/v1`.
- Aliases `coding reasoning fast vision embed auto coder nemotron gpt glm deepseek uncensored web-search` are referenced by `../rag/ ../aider/ ../crush/ ../opencode/ ../codex/ ../qwen-code/ ../zsh/functions/qwen.sh [ai.sh](ai.sh)`. Add — don't rename.
- TTS aliases: `tts` (Gemini, primary), `tts-piper` (local Piper Russian, always available), `tts-azure` (Greek skill), `tts-azure-ru` (Azure Russian fallback). Fallback chain: `tts → tts-piper → tts-azure-ru`. Use `tts` for Russian speech; do NOT use `tts-azure` for Russian (it's voice-agnostic, used by greek-tts skill with explicit Azure voice ids).
- `host.docker.internal` api_base entries (`tts-piper` on `:8177`, `voiceink-local` on `:8178`) are local shims — free, no paid quota. `verify-free-only.sh` whitelists this host explicitly.
- Port stays `127.0.0.1:4000`. UI creds stay `${LITELLM_UI_*:?...}` — never hardcoded.
- `embed` alias uses `nvidia/llama-nemotron-embed-vl-1b-v2:free` (1024-dim). Changing the model breaks every Qdrant collection that used it — coordinate with `../rag/`.

## Caching

Redis semantic cache via RediSearch (vector KNN). Key facts:
- **Redis image:** `redis/redis-stack-server` (not plain `redis:alpine`) — required for RediSearch module.
- **Embedding model:** `mistral/mistral-embed` — called on every request to vectorize the prompt. Uses `MISTRAL_API_KEY` from docker-compose env. Do NOT set `redis_semantic_cache_embedding_model` to a `model_list` alias — it runs before the proxy model router is initialized (chicken-and-egg). Must be a provider-prefixed model string resolvable by LiteLLM directly.
- **Similarity threshold:** 0.85 — cosine similarity ≥ 85% = cache hit; lower = more hits but risk of wrong cached responses.
- **TTL:** 86400s (24h).
- **Changing the embedding model:** flush the index first, then restart: `docker exec litellm-redis redis-cli FT.DROPINDEX litellm_semantic_cache_index DD && docker compose restart litellm`.
- **`REDIS_PASSWORD: ""`** must be set in litellm's docker-compose env — LiteLLM validates this env var exists for `redis-semantic` type even when Redis has no auth.

## After any change

```bash
scripts/verify-free-only.sh && docker compose restart
curl -s http://localhost:4000/v1/models -H "Authorization: Bearer sk-local-workbot" | jq -r '.data[].id'
```
