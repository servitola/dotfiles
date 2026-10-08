#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

if [[ -n "${CI:-}" ]]; then
    section "CI: skip docker compose (no Docker on macOS runners)"
    section "CI: skip cron install (no crontab on runners)"
    exit 0
fi

if [[ -n "${NO_DOCKER:-}" ]]; then
    section "NO_DOCKER: skip docker compose"
else
    section "LiteLLM (LLM proxy)"
    ( cd "$DOTFILES/litellm" && docker compose up -d )

    section "docker-logger (container log collection)"
    ( cd "$DOTFILES/docker-logger" && docker compose up -d )
fi

section "cron jobs"
"$DOTFILES/cron/init-cron-jobs.sh"
