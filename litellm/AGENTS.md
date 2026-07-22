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
- Cloudflare Workers AI deployments use `openai/@cf/<slug>` + `api_base: https://api.cloudflare.com/client/v4/accounts/<account-id>/ai/v1` (the OpenAI-compat endpoint; NOT LiteLLM's native `cloudflare/` provider). Key `CLOUDFLARE_API_KEY` (the `cfut_` Workers-AI token — distinct from `CLOUDFLARE_API_TOKEN`, the `cfat_` DNS/tunnel token). Free: 10 000 neurons/day, no billing on the free plan (over-quota → 429). `verify-free-only.sh` whitelists the `api.cloudflare.com/.../ai/v1` host by prefix. Aliases: `cloudflare-kimi-code` (K2.7 Code), `cloudflare-llama` (3.3-70b-fp8-fast), `cloudflare-llama-guard` (Llama Guard 3 8B — separate moderation bucket, NOT in the `moderation` shuffle to avoid guard-verdict-format roulette); also order:2 members of `coding`/`fast`/`reasoning` (reasoning = `@cf/qwen/qwq-32b`). Gated on CF free (403, don't add): GLM-5.2, llama-3.2-11b-vision.
- Aliases `coding reasoning fast vision embed auto coder nemotron gpt glm uncensored web-search` are referenced by `../rag/ ../aider/ ../crush/ ../opencode/ ../codex/ ../qwen-code/ ../zsh/functions/qwen.sh [ai.sh](ai.sh)`. Add — don't rename. (`deepseek` direct alias dropped 2026-06-02 — use `nvidia-deepseek`/`sambanova-deepseek`/`reasoning` instead.)
- `extract` alias — gemini-flash-lite with `temperature: 0` for factual extraction (numbers/tables/facts from documents; 1M context, own 1500 RPD bucket). Use it instead of `fast`/`coding` when the task is "pull data out verbatim" — randomness only adds hallucination risk there.
- TTS aliases: `tts` (Gemini, primary), `tts-piper` (local Piper Russian, always available), `tts-kokoro` (local Kokoro-82M ENGLISH via MLX, highest-quality small TTS on Apple Silicon), `tts-azure` (Greek skill), `tts-azure-ru` (Azure Russian fallback). Fallback chain: `tts → tts-piper → tts-azure-ru`. Use `tts` for Russian speech; use `tts-kokoro` for English (Kokoro is English-first — for Russian stay on `tts-piper`); do NOT use `tts-azure` for Russian (it's voice-agnostic, used by greek-tts skill with explicit Azure voice ids).
- `host.docker.internal` api_base entries (`tts-piper` on `:8177`, `voiceink-local` on `:8178`, `tts-kokoro` on `:8179`) are local shims — free, no paid quota. `verify-free-only.sh` whitelists this host explicitly. The Kokoro shim (`kokoro-shim/app.py`, launchd `com.servitola.kokoro-shim`) loads Kokoro-82M on MLX once at startup; `voice` accepts Kokoro voices (`af_*`/`am_*` American, `bf_*`/`bm_*` British), else falls back to `af_heart`.
- Port stays `127.0.0.1:4000`. UI creds stay `${LITELLM_UI_*:?...}` — never hardcoded.
- `embed` alias uses `nvidia/llama-nemotron-embed-vl-1b-v2` **on NVIDIA NIM** (2048-dim, `input_type: query`, `encoding_format: float`). Moved off OpenRouter 2026-07-22 — see the shared-bucket section below. Changing the model breaks every Qdrant collection that used it — coordinate with `../rag/`. Both `input_type: query` and `encoding_format: float` are load-bearing; see the `embed` block in [config.yaml](config.yaml).

### OpenRouter is ONE shared 1000-req/day bucket — don't let a cron eat it

The free tier is **account-wide**, not per-model: 1000 requests/day across every `:free` slug
(`X-RateLimit-Limit: 1000`, resets 03:00 local). Whatever burns it starves *everything* else.

This bit hard on 2026-07-22. `embed` was an OpenRouter deployment and `rag-improve` runs twice an
hour (~130 + ~260 embeddings per run ≈ **9 000 calls/day, ~9× the entire allowance**). Result: all
~30 OpenRouter chat deployments 429'd with `free-models-per-day-high-balance` — `nemotron*`,
`gemma-4*`, `poolside`, plus the whole `moderation` alias and 3/4 of `vision`. It looked like a
dozen unrelated models had died. It was one starved bucket, and the cause was RAG.

Fixed by moving `embed` to NVIDIA NIM, which hosts the **same** model on an independent quota:
`cosine(OpenRouter, NIM input_type=query) = 1.000000` over 2048 dims, so no Qdrant re-embed was
needed. `input_type: query` is load-bearing — `passage` scores only 0.637 against stored vectors.

Rules:
- **Never put a high-volume automated consumer (embeddings, cron jobs, bulk eval) on OpenRouter.**
  Keep it for interactive/low-volume chat. Check `curl https://openrouter.ai/api/v1/key` — but note
  it reports the *credit* limit; the request bucket is only visible in the `X-RateLimit-*` headers
  of an actual 429.
- Before assuming a provider "died", check whether one consumer drained a shared quota.
- Prefer providers with **per-model** buckets (io.net ~500K tokens/day per model, Cloudflare's own
  neuron pool, NIM) for anything on a timer.

### Adding/removing OpenRouter models — avoid the intermittent-400 trap

A `:free` OpenRouter slug is load-balanced across MANY backend providers, and they don't all accept the same request params — some reject `encoding_format`, `response_format`, `tools`, etc. → **sporadic** `400`/`422` that come and go on retry and that `num_retries` can't escape (it re-hits the same bad routing). This bit `embed` (RAG refresh aborted on `encoding_format`). Rules:

- **Pin every OpenRouter deployment to param-compatible backends.** Add to its `litellm_params`:
  ```yaml
      extra_body:
        provider:
          require_parameters: true   # only route to backends that support all sent params
  ```
  Optional steering: `provider: {sort: throughput}`, or `order: [...]` / `ignore: [...]` to avoid known slow/bad backends.
- **Symptom to recognise:** `BadRequestError ... "code":"invalid_value" ... "path":["encoding_format"]` (or any param) — and especially when it's intermittent (some calls 200, some 400). That's backend roulette, not your config or the caller. Diagnose by probing `/v1/embeddings` (or `/chat/completions`) several times; a healthy model is 200 every time.
- **BUT: `encoding_format` specifically was NOT backend roulette.** Diagnosed 2026-07-22 — the `embed` 400 was 5/5 permanent, not sporadic, and `require_parameters: true` did not help. Root cause: when the caller omits `encoding_format`, the OpenAI SDK inside LiteLLM defaults it to **`base64`**, which NVIDIA embeddings reject outright. Fix is `encoding_format: float` in the deployment's `litellm_params` (now set). Check the SDK default before blaming the provider.
- **Fallbacks now exist for the rotation groups too** (`coding → fast → reasoning`, `reasoning → coding`, `fast → coding`, `vision → gemini-flash-lite`), plus `content_policy_fallbacks` for `uncensored`. Direct provider aliases still have NO fallback by design. `embed` still has none: any `embed` fallback MUST be the same model + dimension (2048), or Qdrant queries return garbage.
- **`/v1/models` lists the alias, NOT health.** A model can be listed and still 400 at call time. Always probe the actual endpoint after adding/swapping, not just `models`. **Run `scripts/smoke-test.py`** — that is what it is for.

### Testing that models actually work — `scripts/smoke-test.py`

`check-models.py` is a **catalog** check ("does the provider list this slug?"). It is necessary but
badly insufficient: on 2026-07-22 it reported a healthy config while 26 of 65 aliases failed every
live call. `scripts/smoke-test.py` calls the models.

```bash
scripts/smoke-test.py              # full: /health sweep + per-alias probe + group coverage
scripts/smoke-test.py --quick      # skip the ~60s /health sweep
scripts/smoke-test.py --alias coding
scripts/smoke-test.py --json       # for cron/alerting
```
Exit `0` ok · `1` permanent breakage or a rotation group under its floor · `2` proxy down.
Runs daily at 06:40 via `cron/cron_jobs/litellm-smoke.cron`; log `/tmp/litellm-smoke.log`.

Three non-obvious things it gets right — replicate them in any ad-hoc probe:
1. **Always send `{"cache": {"no-cache": true}}`.** Without it you measure Redis, not the providers.
   The first naive sweep reported 53/65 "OK" at ~0.2 s each; every one was a cache hit. Truth: 39/65.
2. **Use a big `max_tokens` (800+).** At `max_tokens: 16` every reasoning model returns empty
   `content` with `finish_reason: length` — the budget goes to reasoning tokens. Twelve models
   looked dead for exactly this reason and were fine.
3. **Never treat 429 as dead.** On a free-tier pool 429 is the normal steady state. Only
   `permanent` (dead slug / dead key / needs payment) justifies editing `config.yaml`.

**Rotation groups hide rot.** `coding` shuffles across N deployments, so N−1 can be dead without a
single request visibly failing — it was at 8/18 live when this was found. The group-coverage floors
in `GROUP_FLOORS` are the guard; the daily cron is what makes it matter.

## Consumers — what routes through this proxy

This is the **free-tier hub**: the things that talk to an LLM but shouldn't burn
paid quota point at `127.0.0.1:4000`. **The primary AI coding tool — Claude Code —
does NOT route through here**; it uses the paid Anthropic API directly. This proxy
serves the *free* lane: CI/bulk jobs, image work, RAG, the `ai` CLI, and the
experimental coding agents. If you change an alias, port, or the `embed` model,
these break:

- **`ai` CLI + RAG (the real daily consumers):** `ai.sh` (the `ai` command) and `../rag/` — `embed` for every Qdrant collection + chat models for `rag ask/improve/answer-eval`. These two matter day-to-day; everything below is experimental.
- **Experimental coding agents — default model each picks:** `../opencode/` → `coding` (small `fast`); `../qwen-code/` → `coder-model`; `../aider/` → `coding` (weak `glm`). The `auto` model-group and the `coder`/`coder-model`/`qwen-code` aliases all resolve to **`coding`**. Exceptions: `../mistral-vibe/` defaults to its own `devstral-small`; `../codex/` defaults to its own `gpt-5.4-mini` (litellm only via `-c model_provider=litellm -c model=gpt`). All experiments — not used for real coding work; Claude Code is.
- **Other CLIs / shell:** `../zsh/` `functions/qwen.sh` (`qm`), `../mistral-vibe/` (`vibe`), `../aichat/`.
- **Voice/TTS:** `../voiceink/` via the `voiceink-local` shim (:8178), the `greek-tts` skill via `tts-azure`, `piper-shim/` via `tts-piper` (:8177).

Invariant: the proxy (and its docker stack) must be **up first** — `rag status`
checks it. Consumers fail loudly if it's down (fail-fast convention).

## Caching

**Exact-match** Redis cache (`cache_params.type: redis`), TTL 24h,
`supported_call_types: ["acompletion", "atext_completion"]` so embeddings and audio are never cached.

### Why NOT semantic — a real correctness bug, do not re-enable casually

`redis-semantic` was dropped 2026-07-22. It keys on the **prompt embedding only, not the model**.
One prompt sent to four unrelated aliases returned the byte-identical response id:

```
mistral-small / groq-llama / cohere-command-a / cloudflare-llama
  -> id=d005e3757cb7484ea0de1bdf20134898  'Titan'    (the 4th was a PARAPHRASE)
```

LiteLLM rewrites the response's `model` field to whatever the caller asked for, so the substitution
is **invisible downstream**. Real consequences: `moderation` / `cloudflare-llama-guard` safety
verdicts could be served by a general chat model; `vision` could return a text model's reply; and
every model-vs-model comparison through this proxy was meaningless.

Verify after any cache change — this is the regression test:
```bash
# same prompt, different aliases -> ids MUST differ; repeating one alias MUST hit cache
for m in mistral-small groq-llama cohere-command-a; do
  curl -s localhost:4000/v1/chat/completions \
    -H "Authorization: Bearer ${LITELLM_MASTER_KEY:?}" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$m\",\"messages\":[{\"role\":\"user\",\"content\":\"Largest moon of Saturn? one word\"}],\"max_tokens\":64}" \
    | jq -r '"\(.model)  \(.id)"'
done
```

Other facts:
- **Redis image:** `redis/redis-stack-server`. Still required *if* you ever go back to semantic
  (RediSearch module); harmless for exact-match.
- **Cost of exact-match:** no paraphrase hits, so a lower hit rate and slightly more quota burn.
  Correct answers are worth more. It also subsumes two older workarounds — the 0.85→0.92 threshold
  bump (гречка vs рис) and the vision/image-bytes hazard — because exact keys hash the whole request
  body, images and model included.
- Per-request `{"cache":{"no-cache":true}}` still works and is still correct in callers that use it
  (`bin/foodai.sh`). **Mandatory in any health/benchmark probe.**
- **If you re-enable semantic:** `redis_semantic_cache_embedding_model` must be a provider-prefixed
  string (`mistral/mistral-embed`), never a `model_list` alias — the cache resolver runs before the
  router exists. `REDIS_PASSWORD: ""` must be in litellm's compose env. Flush first:
  `docker exec litellm-redis redis-cli FT.DROPINDEX litellm_semantic_cache_index DD`.

## After any change

```bash
scripts/verify-free-only.sh && docker compose restart
scripts/smoke-test.py          # models must actually ANSWER, not just be listed
```
`/v1/models` only proves an alias is registered. Use the smoke test.
