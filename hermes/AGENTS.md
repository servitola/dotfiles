# hermes — config for the Nous Research Hermes agent CLI

> **Status:** experiment — not in active use. See `docs/repo-map.md`.

- `config.yaml` is the only tracked file: the full Hermes settings tree (model/provider, agent loop limits, toolsets, terminal/web/browser backends, per-platform chat integrations, memory, skills, security). Default model is `stepfun/step-3.7-flash:free` via the Nous inference gateway.
- Makefile (target near `setup Hermes`) symlinks it to `~/.hermes/config.yaml`. Edit this file, not the symlink.
- `~/.hermes/` (live, untracked) holds the runtime: `auth.json`, `state.db`, `sessions/`, `skills/`, `memories/`, caches — none of it belongs in dotfiles.
- `platform_toolsets` maps each chat surface (cli, telegram, discord, slack, signal, ...) to its `hermes-<platform>` toolset; `personalities` under `agent` defines the named system-prompt presets.
- The commented `fallback_model` block at the file end documents optional provider failover; it ships disabled.
