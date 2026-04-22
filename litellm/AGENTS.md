# litellm — agent rules

- Free models only. After any [config.yaml](config.yaml) edit: `scripts/verify-free-only.sh` must exit 0.
- OpenRouter deployments use `openai/<slug>` + `api_base: https://openrouter.ai/api/v1`. Never `openrouter/<slug>`.
- Groq deployments use native `groq/<slug>` (no `api_base`).
- Z.AI deployments use native `zai/<slug>` (no `api_base`).
- Aliases `coding reasoning fast vision embed auto coder nemotron gpt glm` are referenced by `../rag/ ../aider/ ../crush/ ../opencode/ ../codex/ ../qwen-code/ ../zsh/functions/qwen.sh [ai.sh](ai.sh)`. Add — don't rename.
- Port stays `127.0.0.1:4000`. UI creds stay `${LITELLM_UI_*:?...}` — never hardcoded.
- `embed` alias output is 2048-dim. Changing the model breaks every Qdrant collection that used it.

After any change:

```bash
scripts/verify-free-only.sh && docker compose restart
curl -s http://localhost:4000/v1/models -H "Authorization: Bearer sk-local-workbot" | jq -r '.data[].id'
```
