# LiteLLM Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `dotfiles/litellm/` into the private service repository `~/projects/services/litellm` behind `DIR_LITELLM`, with the proxy, the five launchd shims and the aliases running from the new place.

**Architecture:** `git subtree split` carries the history; the working files git ignores (`f5-shim/tmp`, shim logs, `model-health.json`) are copied; every consumer reads `$DIR_LITELLM`; the compose stack and the five LaunchAgents are re-pointed and restarted one by one with a port check after each.

**Tech Stack:** zsh, git subtree, docker compose (OrbStack), launchctl, perl in-place edits.

Spec: `docs/superpowers/specs/2026-10-10-litellm-extraction-design.md`.

## Global Constraints

- Repository `~/projects/services/litellm`, private on Gitea. Constant `DIR_LITELLM=$HOME/projects/services/litellm`.
- Launchd plists keep absolute paths (launchd expands nothing); everything else uses `$DIR_LITELLM`.
- Shim ports: f5 8181, kokoro 8179, parakeet 8180, piper 8177, voiceink 8178; proxy `$LITELLM_URL` (4000).
- `rm` is aliased to `trash`; `/bin/rm` for a real delete. Never push dotfiles; push the new repository.
- Dotfiles commits run with `PATH=/opt/homebrew/opt/python@3/libexec/bin:$PATH` (constants hook needs python 3.14).

---

### Task 1: Repository with history and working files

- [ ] Baseline: `curl -s $LITELLM_URL/v1/models | jq '.data|length'`; `for p in 8177 8178 8179 8180 8181; do curl -so /dev/null -w "$p %{http_code}\n" http://127.0.0.1:$p/health || true; done`; `docker ps --format '{{.Names}}' | grep litellm | wc -l` → 3.
- [ ] `git subtree split --prefix=litellm -b litellm-history`; `mkdir ~/projects/services/litellm && cd … && git init -q -b master && git pull -q ~/projects/dotfiles litellm-history`; delete the branch in dotfiles.
- [ ] `rsync -a --exclude __pycache__ --exclude .DS_Store ~/projects/dotfiles/litellm/ ~/projects/services/litellm/` (brings `f5-shim/tmp`, `*-shim/logs`, `model-health.json`); `diff -rq` → SAME.
- [ ] `.gitignore` is tracked already (`.env`, `model-health.json`, `__pycache__`, `*.pyc`, `*-shim/logs/`); add `f5-shim/tmp/` and `.DS_Store` if missing. Commit.

### Task 2: Constant and consumers

- [ ] `constants.env`: `DIR_LITELLM=$HOME/projects/services/litellm` after `DIR_RAG`; `schema.toml`: `DIR_LITELLM = { type = "dir", about = "LiteLLM proxy and TTS/STT shims (~/projects/services/litellm)" }`.
- [ ] dotfiles: `zsh/zshrc.sh:57` → `source "${DIR_LITELLM:?}/ai.sh"`; `macos_update/update_all.sh:96` → `python3 "${DIR_LITELLM:?}/scripts/check-models.py"`; `python/install-tts.sh:25` → `PLIST_SRC="${DIR_LITELLM:?}/piper-shim/com.servitola.piper-shim.plist"`; `docker/compose-projects.txt:7` → `projects/services/litellm`; `docs/repo-map.md:17` → says it moved; `docs/commands.md:17` → `$DIR_LITELLM/config.yaml`; `zsh/bin/litellm-config-diff` if it names the path.
- [ ] outside: `~/projects/cron/cron_jobs/monitoring/litellm-smoke.cron` → `$DIR_LITELLM/scripts/smoke-test.py`; `~/projects/rag/{rag.sh,README.md,AGENTS.md}` → `$DIR_LITELLM`; `~/projects/skills/skills/{tts,greek-tts}` docs → `$DIR_LITELLM`; new repo `scripts/verify-free-only.sh:38` usage line.
- [ ] `grep -rn 'dotfiles/litellm'` over dotfiles, cron, rag, skills → nothing.

### Task 3: Live services

- [ ] Compose: `cd ~/projects/services/litellm && docker compose up -d` → containers adopted; `docker ps --format '{{.Names}}\t{{.Label "com.docker.compose.project.working_dir"}}' | grep litellm` shows the new dir; `curl $LITELLM_URL/v1/models` answers.
- [ ] LaunchAgents: in the new repo's five plists nothing changes (they were templates); in `~/Library/LaunchAgents`: rewrite the dotfiles path to the new absolute path in the three copies (f5, piper, voiceink); re-create the two symlinks (kokoro, parakeet) to the new repo; for each: `launchctl bootout gui/$UID/<label>; launchctl bootstrap gui/$UID ~/Library/LaunchAgents/<label>.plist`; then the port check from Task 1 → same codes as baseline.
- [ ] `_EXPORTS_LOADED= zsh -ic 'type ai' ` → alias from `$DIR_LITELLM/ai.sh`.

### Task 4: Remove from dotfiles, docs, remote

- [ ] `git rm -rq litellm && /bin/rm -rf litellm`; new repo `AGENTS.md` gets a "moved out of dotfiles, DIR_LITELLM" paragraph; dotfiles `AGENTS.md` handoff paragraph.
- [ ] `python3 constants/check.py`; `pre-commit run --all-files`; commit dotfiles (`[litellm] move the proxy and the shims to ~/projects/services/litellm`), commit cron/rag/skills, push cron and skills (rag has no remote).
- [ ] Gitea: create private `litellm` via the API, `git remote add origin …/servitola/litellm.git`, `git push -u origin master`.
