#!/bin/zsh
# Bring up all docker-compose services listed in compose-projects.txt.
# Missing paths are skipped with a warning (no auto-clone).

set -u

# Make compose variable substitution work from non-interactive shells (cron,
# launchd, Makefile). openai_key.sh lives in $HOME and is not in the repo.
if [ -f "$HOME/.config/openai_key.sh" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.config/openai_key.sh"
fi

REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.txt"

echo "🐳 Starting docker-compose services from $REGISTRY"

while IFS= read -r rel || [ -n "$rel" ]; do
    [[ -z "$rel" || "$rel" =~ ^[[:space:]]*# ]] && continue
    dir="$HOME/$rel"
    if [ ! -d "$dir" ]; then
        echo "⚠️  Skip (missing dir): $rel"
        continue
    fi
    if [ ! -f "$dir/docker-compose.yml" ] && [ ! -f "$dir/docker-compose.yaml" ] \
        && [ ! -f "$dir/compose.yml" ] && [ ! -f "$dir/compose.yaml" ]; then
        echo "⚠️  Skip (no compose file): $rel"
        continue
    fi
    echo "▶️  $rel"
    (cd "$dir" && docker compose up -d)
done < "$REGISTRY"

echo "✅ Done"
