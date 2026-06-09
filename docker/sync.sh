#!/bin/zsh
# Refresh compose-projects.txt from currently-running docker compose projects.

set -eu
REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.txt"
# Entries listed in the gitignored private overlay are kept out of the
# public registry (up.sh reads both files).
PRIVATE_REGISTRY="$HOME/projects/dotfiles/docker/compose-projects.private.txt"
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

if [ -f "$PRIVATE_REGISTRY" ]; then
    grep -vxF -f <(grep -v '^[[:space:]]*#' "$PRIVATE_REGISTRY") "$TMP" > "$TMP.pub" || true
    mv "$TMP.pub" "$TMP"
fi

mv "$TMP" "$REGISTRY"
echo "✅ Registry updated. Review with: git diff docker/compose-projects.txt"
