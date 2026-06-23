# docker — registry-driven starter that keeps all dotfiles docker-compose services running

- `compose-projects.txt` — the registry: one $HOME-relative dir per line (each must hold a compose file). Comments (`#`) and blanks ignored. Source of truth for "which stacks should be up".
- `up.sh` — idempotent reconciler over the registry: skips already-fully-running projects, runs `pull → build → up -d` on down/partial ones, warns and skips missing dirs or dirs without a compose file (no auto-clone). Sources `~/.config/openai_key.sh` first so compose var substitution works from non-interactive shells (cron/launchd).
- `sync.sh` — reverse direction: regenerates `compose-projects.txt` from `docker compose ls` (currently-running projects). Run after adding/removing a stack so the registry matches reality.
- `up.sh` is wired into the `up` command via `macos_update/update_all.sh`, so every system update brings all registered stacks up.
- Registered stacks living in this repo: `litellm/` (LiteLLM proxy), `qdrant/` (vector DB), `docker-logger/` — each has its own `docker-compose.yml` + `AGENTS.md`. Other stacks live outside dotfiles under `~/projects/` and are registered via the gitignored `compose-projects.private.txt` overlay.
- Invariant: this dir only orchestrates compose; it defines no services itself. To add a stack, drop a compose file in its dir and add the $HOME-relative path to the registry (or run `sync.sh`).
- Start everything by hand: `bash ~/projects/dotfiles/docker/up.sh`
