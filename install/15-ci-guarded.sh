#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

if [[ -n "${CI:-}" ]]; then
    section "CI: skip docker compose (no Docker on macOS runners)"
    section "CI: skip cron install (no crontab on runners)"
    exit 0
fi

section "docker stacks (docker/compose-projects*.txt)"
zsh "$DOTFILES/docker/up.sh"

section "cron jobs (\$DIR_CRON)"
repository "$DIR_CRON"
[[ ! -d $DIR_CRON_JOBS ]] || "$DOTFILES/cron/install.sh"
