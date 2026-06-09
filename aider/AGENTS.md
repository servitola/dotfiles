# aider — config for the aider AI pair-programmer, routed through the local LiteLLM proxy

> **Status:** experiment — Claude Code is the primary AI coding agent. See `docs/repo-map.md`.

- `aider.conf.yml` aider auto-loads it (symlinked to `~/.aider.conf.yml` by the Makefile). Settings here are defaults; any flag can be overridden at invocation (`aider --model openai/plus`).
- All traffic goes through the LiteLLM proxy at `http://localhost:4000/v1`
