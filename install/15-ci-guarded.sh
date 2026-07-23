#!/bin/zsh
# Step 15 — Docker stacks, private overlay, cron. Skipped on CI ($CI set).
source "${0:a:h}/lib.sh"
set -euo pipefail

if [[ -n "${CI:-}" ]]; then   # ${CI:-} so set -u doesn't trip when CI is unset
    section "CI: skip docker compose (no Docker on macOS runners)"
    section "CI: skip private overlay clone (no auth on runners)"
    section "CI: skip cron install (needs private overlay)"
    exit 0
fi

section "LiteLLM (LLM proxy)"
( cd "$DOTFILES/litellm" && docker compose up -d )

section "docker-logger (container log collection)"
( cd "$DOTFILES/docker-logger" && docker compose up -d )

section "ensure dotfiles_private overlay present"
test -d "$PRIVATE" || \
    git clone https://github.com/servitola/dotfiles_private.git "$PRIVATE"

section "cron jobs"
"$DOTFILES/cron/init-cron-jobs.sh"
