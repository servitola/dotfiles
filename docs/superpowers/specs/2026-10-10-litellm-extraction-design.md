# LiteLLM extraction: move `litellm/` out of dotfiles into `~/projects/services/litellm`

**Status:** approved 2026-10-10, not implemented.

## Why

`litellm/` is a running service, not configuration: a `docker compose` stack
(proxy, postgres, redis), five launchd shims (f5, kokoro, parakeet, piper,
voiceink), `ai.sh` aliases, health and smoke scripts, `greek-tts.sh`. Services
live in `~/projects/services/` (gitea, worknamevpn, golos_ru); dotfiles keeps
only what points at them. Same pattern as cron, skills and forks.

## Design

**Repository.** `~/projects/services/litellm`, private on Gitea, history via
`git subtree split` (60 commits). Content moves one to one, including the
git-ignored working files: `f5-shim/tmp/` (the voice reference the f5 shim
caches for its process lifetime), `*-shim/logs/`, `model-health.json`.

**Constant.** `DIR_LITELLM=$HOME/projects/services/litellm`. `LITELLM_URL`
already exists.

**Dotfiles consumers → `$DIR_LITELLM`:** `zsh/zshrc.sh` (`source … /ai.sh`),
`macos_update/update_all.sh` (check-models), `python/install-tts.sh` (piper
plist), `docker/compose-projects.txt` (stack path), `docs/repo-map.md`,
`docs/commands.md` if it names the directory. Outside: `cron`
(`monitoring/litellm-smoke.cron`), `rag` (`rag.sh`, `README.md`, `AGENTS.md`),
`skills` (`tts`, `greek-tts` docs), `scripts/verify-free-only.sh` usage line.

**Live services.**
- Docker: the compose project name is the directory name `litellm`, unchanged;
  volumes are named (`litellm_postgres_data`, `litellm_redis_data`); binds are
  relative. `docker compose up -d` from the new directory re-adopts the
  containers; the database is untouched.
- LaunchAgents: `com.servitola.{f5,piper,voiceink}-shim.plist` in
  `~/Library/LaunchAgents` are copies with absolute paths, `kokoro` and
  `parakeet` are symlinks into dotfiles. All five get the new path and a
  `bootout`/`bootstrap`. The f5 restart is required anyway: it caches the
  reference path.
- `f5-shim/com.servitola.f5-shim.i9.plist` points at `~/services/f5-tts` on the
  other Mac; untouched.

**Verification.** `curl $LITELLM_URL/v1/models` answers; `docker ps` shows the
three containers with the new working dir; five shims in `launchctl list` and
answering on their ports; `ai` aliases in a fresh shell; `python3
constants/check.py`; `pre-commit run --all-files`; no `litellm/` in dotfiles.

## Out of scope

The i9 copy of the f5 shim; the `golos_ru` voice project the f5 shim reads.
