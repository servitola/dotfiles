# LiteLLM — free model proxy

Local OpenAI/Anthropic-compatible proxy over twelve free upstreams (OpenRouter `:free`, Groq, Cerebras, NVIDIA NIM, GitHub Models, Z.AI, Mistral, Gemini, SambaNova, Chutes, LLM7, plus Together AI on expiring trial credits) with automatic rotation.

- **Endpoint:** `http://localhost:4000`
- **Master key:** `sk-local-workbot`
- **Admin UI:** http://localhost:4000/ui (creds from `~/.config/openai_key.sh`)

## Start / stop

```bash
cd ~/projects/dotfiles/litellm && docker compose up -d
docker compose restart           # after editing config.yaml
docker compose down              # stops; volume survives
```

Or via dotfiles auto-start: `bash ~/projects/dotfiles/docker/up.sh`.

## Smoke test

```bash
curl -s http://localhost:4000/health/liveliness
curl -s http://localhost:4000/v1/models -H "Authorization: Bearer sk-local-workbot" | jq -r '.data[].id'
```

## Aliases

| kind | names |
|---|---|
| direct (OpenRouter) | `nemotron`, `nemotron-ultra`, `nemotron-omni`, `gpt`, `gpt-oss-20b`, `glm`, `glm-air`, `poolside-laguna`, `uncensored`, `vision`, `embed` |
| direct (Mistral) | `mistral-codestral`, `mistral-small`, `mistral-large`, `mistral-magistral`, `mistral-magistral-small` |
| direct (Cerebras) | `cerebras-glm`, `cerebras-gpt-oss` |
| direct (NVIDIA NIM) | `nvidia-nemotron`, `nvidia-nemotron-120b`, `nvidia-kimi`, `nvidia-deepseek`, `nvidia-deepseek-flash` |
| direct (Groq) | `groq-llama`, `groq-gpt-oss`, `groq-compound`, `groq-compound-mini` |
| direct (GitHub) | `github-gpt4o-mini`, `github-deepseek-r1` |
| direct (Gemini) | `gemini`, `gemini-flash-lite`, `gemini-search` |
| direct (SambaNova) | `sambanova-deepseek`, `sambanova-llama`, `sambanova-maverick`, `sambanova-minimax`, `sambanova-gpt-oss` |
| direct (Chutes) | `chutes-qwen-thinking`, `chutes-qwen-coder`, `chutes-qwen-small`, `chutes-deepseek`, `chutes-kimi`, `chutes-glm`, `chutes-minimax` |
| direct (Together, trial) | `together-magistral`, `together-qwen-thinking`, `together-qwen-coder`, `together-deepseek`, `together-llama`, `together-minimax` |
| direct (LLM7, anon) | `llm7-qwen`, `llm7-mistral`, `llm7-codestral` |
| rotation (shuffle + cooldown) | `coding` (default for `auto`), `reasoning`, `fast`, `vision`, `web-search` |
| web search | `gemini-search`, `groq-compound`, `web-search` |
| TTS | `tts`, `tts-pro`, `tts-piper`, `tts-azure`, `tts-azure-ru` |
| STT | `voiceink-local` |
| embeddings | `embed` (1024-dim, OpenRouter/NVIDIA) |
| image generation | `image-edit` (Gemini 2.5 Flash Image) |

`model_group_alias`: `coder`, `coder-model`, `qwen-code`, `qwen3-coder-plus` → `coding`; `auto` → `coding`.

Full routing in [config.yaml](config.yaml). Add a model = new block under the right `model_name:`, then `docker compose restart`.

## TTS (text-to-speech)

| alias | backend | notes |
|---|---|---|
| `tts` | Gemini 2.5 Flash TTS | primary; free 15 RPM, multilingual, voice e.g. `Kore` |
| `tts-pro` | Gemini 2.5 Pro TTS | better prosody, same quota pool |
| `tts-piper` | Piper (local) | Russian only; always free, no quota; shim on `:8177` |
| `tts-azure` | Azure Neural | voice-agnostic; used by `greek-tts` skill explicitly |
| `tts-azure-ru` | Azure Neural | forces `ru-RU-DmitryNeural`; last-resort Russian fallback |

**Fallback chain for `tts`:** Gemini → `tts-piper` → `tts-azure-ru`

### Piper shim

Local FastAPI shim at `~/projects/dotfiles/litellm/piper-shim/app.py`, launchd agent `com.servitola.piper-shim`, port `127.0.0.1:8177`. Piper venv at `~/.venv/tts`, voice model at `~/.local/share/piper-voices/ru_RU-irina-medium.onnx`.

```bash
# health check
curl http://127.0.0.1:8177/health

# logs
tail -f ~/projects/dotfiles/litellm/piper-shim/logs/launchd.err.log

# restart shim
launchctl unload ~/Library/LaunchAgents/com.servitola.piper-shim.plist
launchctl load   ~/Library/LaunchAgents/com.servitola.piper-shim.plist
```

## Caching

Response cache in Redis — same or semantically similar prompt + same model → instant response from cache, no upstream call, no quota consumed.

**Stack:** `redis/redis-stack-server` (provides RediSearch for vector similarity). Config: `docker-compose.yml` → `redis` service, `config.yaml` → `litellm_settings.cache_params`.

| param | value | notes |
|---|---|---|
| type | `redis-semantic` | vector similarity search via RediSearch |
| TTL | 24 h | keys expire after 24 hours |
| similarity threshold | 0.85 | cosine similarity ≥ 85% = cache hit |
| embedding model | `mistral/mistral-embed` | called at every lookup to vectorize the prompt; uses `MISTRAL_API_KEY` |

**How it works:** on every request LiteLLM calls `mistral-embed` to get a vector for the incoming prompt, runs a KNN search in the `litellm_semantic_cache_index` index, and returns the stored response if the nearest neighbor has similarity ≥ 0.85. On miss, the upstream is called and the response + vector are stored with TTL 24h.

**Monitoring hit rate:**

```bash
docker exec litellm-redis redis-cli INFO stats | awk -F: '
  /keyspace_hits/   { h=$2+0 }
  /keyspace_misses/ { m=$2+0 }
  END { printf "hits=%d miss=%d hit_rate=%.1f%%\n", h, m, (h+m>0 ? h/(h+m)*100 : 0) }'
```

**Diagnostics:**

```bash
docker exec litellm-redis redis-cli ping              # Redis alive
docker exec litellm-redis redis-cli FT._LIST          # should show litellm_semantic_cache_index
docker exec litellm-redis redis-cli DBSIZE            # key count
docker exec litellm-redis redis-cli INFO memory | grep used_memory_human
```

**Changing the embedding model:** if you swap `redis_semantic_cache_embedding_model`, the vector dimensions change — flush the semantic index first:

```bash
docker exec litellm-redis redis-cli FT.DROPINDEX litellm_semantic_cache_index DD
docker compose restart litellm   # proxy recreates the index on startup
```

## $0 guarantee

1. [scripts/verify-free-only.sh](scripts/verify-free-only.sh) — walks every deployment and checks `(model, api_base)` against a whitelist (OpenRouter `:free` / Groq / Z.AI / Gemini / Mistral / Cerebras / NVIDIA NIM / GitHub Models / SambaNova / Chutes / LLM7 / local shims / Azure Speech). Run before every config change; must exit 0.
2. Together AI (`api.together.xyz`) is whitelisted as **trial credits, not a recurring free tier** — once the trial balance is spent it bills. The script flags it (`trial credits — EXPIRE`) but can't see the balance; watch it in the Together dashboard.
3. Port 4000 bound to `127.0.0.1` only.
4. Set a ~$0.01 OpenRouter credit limit — free models don't debit, any accidental paid call returns 402.

## Connected CLIs

All tools share this proxy and `sk-local-workbot`. Configs live in their own dotfiles modules: [claude-local alias](~/.config/openai_key.sh), [qwen-code](../qwen-code/), [opencode](../opencode/), [crush](../crush/), [aider](../aider/). Non-interactive helper: `ai "..."` from [ai.sh](ai.sh).

## Diagnostics

```bash
docker compose logs -f litellm
rtk proxy docker logs litellm | grep -i '429\|rate'  # rate limits (unfiltered)

# Cache hit rate
docker exec litellm-redis redis-cli INFO stats | awk -F: '
  /keyspace_hits/   { h=$2+0 }
  /keyspace_misses/ { m=$2+0 }
  END { printf "hits=%d miss=%d hit_rate=%.1f%%\n", h, m, (h+m>0 ? h/(h+m)*100 : 0) }'

# Watch live ops/sec
watch -n2 'docker exec litellm-redis redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses|instantaneous_ops"'
```
