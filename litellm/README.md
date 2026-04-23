# LiteLLM — free model proxy

Local OpenAI/Anthropic-compatible proxy over nine free upstreams (OpenRouter `:free`, Groq, Cerebras, NVIDIA NIM, GitHub Models, Z.AI, Mistral, Gemini) with automatic rotation.

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
| direct | `coder`, `nemotron`, `gpt`, `glm`, `gemini`, `vision`, `embed` |
| direct (Mistral) | `mistral-codestral`, `mistral-small`, `mistral-large` |
| direct (Cerebras) | `cerebras-qwen`, `cerebras-llama` |
| rotation (shuffle + cooldown) | `coding` (default for `auto`), `reasoning`, `fast` |
| provider-specific | `groq-*`, `nvidia-*`, `github-*` |

Full routing in [config.yaml](config.yaml). Add a model = new block under the right `model_name:`, then `docker compose restart`.

## $0 guarantee

1. [scripts/verify-free-only.sh](scripts/verify-free-only.sh) — walks every deployment and checks `(model, api_base)` against a whitelist (OpenRouter `:free` / Groq / Z.AI / Gemini / Mistral / Cerebras / NVIDIA NIM / GitHub Models). Run before every config change.
2. Port 4000 bound to `127.0.0.1` only.
3. Set a ~$0.01 OpenRouter credit limit — free models don't debit, any accidental paid call returns 402.

## Connected CLIs

All tools share this proxy and `sk-local-workbot`. Configs live in their own dotfiles modules: [claude-local alias](~/.config/openai_key.sh), [qwen-code](../qwen-code/), [opencode](../opencode/), [crush](../crush/), [aider](../aider/). Non-interactive helper: `ai "..."` from [ai.sh](ai.sh).

## Diagnostics

```bash
docker compose logs -f litellm
docker compose logs litellm | grep -i '429\|rate'   # rate limits
```
