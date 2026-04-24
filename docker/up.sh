#!/bin/zsh
# Ensure all docker-compose services listed in compose-projects.txt are running.
# Already-running projects are skipped (no pull/rebuild/restart).
# Down or partially-down projects get pull + build + up.
# Missing paths are skipped with a warning (no auto-clone).

set -u

# Make compose variable substitution work from non-interactive shells (cron,
# launchd, Makefile). openai_key.sh lives in $HOME and is not in the repo.
if [ -f "$HOME/.config/openai_key.sh" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.config/openai_key.sh"
fi

REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.txt"

while IFS= read -r rel || [ -n "$rel" ]; do
    [[ -z "$rel" || "$rel" =~ ^[[:space:]]*# ]] && continue
    dir="$HOME/$rel"
    if [ ! -d "$dir" ]; then
        echo "  * Skip (missing dir): $rel"
        continue
    fi
    if [ ! -f "$dir/docker-compose.yml" ] && [ ! -f "$dir/docker-compose.yaml" ] \
        && [ ! -f "$dir/compose.yml" ] && [ ! -f "$dir/compose.yaml" ]; then
        echo "  * Skip (no compose file): $rel"
        continue
    fi
    _total=$(docker compose --project-directory "$dir" config --services 2>/dev/null | wc -l | tr -d ' ')
    _running=$(docker compose --project-directory "$dir" ps --status running -q 2>/dev/null | wc -l | tr -d ' ')
    if [ "$_running" -ge "$_total" ] && [ "$_total" -gt 0 ]; then
        echo "  * Already running: $(basename "$dir")"
        continue
    fi
    echo "  ▶ Starting $(basename "$dir")"
    docker compose --project-directory "$dir" pull --ignore-buildable
    docker compose --project-directory "$dir" build --pull
    docker compose --project-directory "$dir" up -d
done < "$REGISTRY"
