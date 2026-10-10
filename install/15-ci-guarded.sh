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

section "cron jobs"
# The jobs live in their own repository, next to this one on the same server.
# Cloning asks first: it is the owner's schedule, not every Mac needs it.
cron_repo="${$(git -C "$DOTFILES" remote get-url origin):h}/cron.git"
if [[ ! -d $DIR_CRON && -t 0 ]] && read -q "?      clone $cron_repo into ${DIR_CRON/#$HOME/~}? [y/N] "; then
    print
    git clone -q "$cron_repo" "$DIR_CRON"
fi
if [[ -d $DIR_CRON_JOBS ]]; then
    "$DOTFILES/cron/install.sh"
else
    print
    warn "no ${DIR_CRON_JOBS/#$HOME/~}: crontab left as it is"
fi
