#!/bin/zsh
# Ensure the docker-compose stacks listed for this machine in compose-projects*.txt are running.
# Already-running projects are skipped (no pull/rebuild/restart).
# Down or partially-down projects get pull + build + up.
# Missing paths are skipped with a warning (no auto-clone).

set -u

if [ "$DOCKER" = no ]; then
    echo "  * DOCKER=no in constants.env: skip docker stacks"
    exit 0
fi

# Make compose variable substitution work from non-interactive shells (cron,
# launchd, Makefile). $FILE_SECRETS is not in the repo.
if [ -f "$FILE_SECRETS" ]; then
    # shellcheck disable=SC1091
    source "$FILE_SECRETS"
fi

REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.txt"
# Optional local overlay for stacks
# that should not be listed in the public registry.
PRIVATE_REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.private.txt"

machine=$(scutil --get LocalHostName)
running=0
{ cat "$REGISTRY"; [ -f "$PRIVATE_REGISTRY" ] && cat "$PRIVATE_REGISTRY"; true; } | \
while read -r rel machines || [ -n "$rel" ]; do
    [[ -z "$rel" || "$rel" =~ ^[[:space:]]*# ]] && continue
    [[ " $machines " == *" $machine "* ]] || continue
    dir="$HOME/$rel"
    [[ "$rel" == /* ]] && dir="$rel"   # an absolute path: a stack on an external drive
    if [ ! -d "$dir" ]; then
        echo "  * Skip (missing dir): $rel"
        continue
    fi
    if [ ! -f "$dir/docker-compose.yml" ] && [ ! -f "$dir/docker-compose.yaml" ] \
        && [ ! -f "$dir/compose.yml" ] && [ ! -f "$dir/compose.yaml" ]; then
        echo "  * Skip (no compose file): $rel"
        continue
    fi
    # Only services meant to stay up count: a job service without a restart policy
    # (mma's scraper, run by launchd) would otherwise "start" the stack on every run.
    _total=$(docker compose --project-directory "$dir" config --format json 2>/dev/null \
        | jq '[.services[] | select((.restart // "no") != "no")] | length')
    _running=$(docker compose --project-directory "$dir" ps --status running -q 2>/dev/null | wc -l | tr -d ' ')
    if [ "$_running" -ge "$_total" ] && [ "$_total" -gt 0 ]; then
        running=$((running + 1))
        continue
    fi
    echo "  ▶ Starting $(basename "$dir")"
    docker compose --project-directory "$dir" pull --ignore-buildable
    docker compose --project-directory "$dir" build --pull
    docker compose --project-directory "$dir" up -d
done
echo "  * $running stacks already running on $machine"
