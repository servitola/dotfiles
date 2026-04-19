#!/bin/zsh
# Refresh compose-projects.txt from currently-running docker compose projects.

set -eu
REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.txt"
TMP="$(mktemp)"

echo "🔄 Syncing $REGISTRY from 'docker compose ls'"

{
    echo "# Auto-synced by docker/sync.sh. Edit by hand to add/remove services."
    echo "# Paths are relative to \$HOME."
    docker compose ls --format json \
        | jq -r '.[].ConfigFiles' \
        | tr ',' '\n' \
        | xargs -n1 dirname \
        | sed "s|^$HOME/||" \
        | sort -u
} > "$TMP"

mv "$TMP" "$REGISTRY"
echo "✅ Registry updated. Review with: git diff docker/compose-projects.txt"
