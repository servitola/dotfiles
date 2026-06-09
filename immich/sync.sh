#!/bin/zsh
# Sync local folders to Immich photo server (mir1 on i9, behind Caddy).
# Idempotent: dedup by hash on server, won't re-upload existing assets.
# Non-destructive: never deletes local files.
#
# Add new folders by appending to SYNC_MAP below.
# Format: "<album-name>::<absolute-path>"

set -u

# Caddy on mir1 serves self-signed cert. NODE_EXTRA_CA_CERTS won't work because
# Node fetch/undici drops SNI for IP literals (RFC 6066), so server returns the
# wrong cert and altname check fails. Until DDNS+LE is set up — disable verify.
export NODE_TLS_REJECT_UNAUTHORIZED=0
export PATH="$HOME/.npm-global/bin:$PATH"

# Server address lives in the gitignored immich.private.env overlay
# (symlink into ~/projects/dotfiles_private) so the public repo does not
# expose it. Soft-exit keeps `up` runs green on machines without it.
ENV_FILE="${0:A:h}/immich.private.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "  * Skip: immich.private.env missing (private overlay not installed)"
    exit 0
fi
source "$ENV_FILE"  # sets IMMICH_URL

if ! command -v immich >/dev/null 2>&1; then
    echo "  * Skip: immich CLI not installed (npm i -g @immich/cli)"
    exit 0
fi

code=$(curl -ks --max-time 5 -o /dev/null -w "%{http_code}" "$IMMICH_URL/api/server/ping" 2>/dev/null)
if [ "$code" != "200" ]; then
    echo "  * Skip: Immich server unreachable at $IMMICH_URL (HTTP $code)"
    exit 0
fi

SYNC_MAP=(
    "Photo Booth::$HOME/Pictures/Photo Booth Library/Pictures"
)

IGNORE_PATTERNS=(
    "**/*.xmp"
    "**/.DS_Store"
    "**/Thumbs.db"
)

ignore_args=()
for pat in "${IGNORE_PATTERNS[@]}"; do
    ignore_args+=(--ignore "$pat")
done

for entry in "${SYNC_MAP[@]}"; do
    album="${entry%%::*}"
    folder="${entry##*::}"
    if [ ! -d "$folder" ]; then
        echo "  * Skip (missing): $folder"
        continue
    fi
    echo "  ▶ $album ← $folder"
    immich upload --recursive --no-progress \
        --album-name "$album" \
        "${ignore_args[@]}" \
        "$folder"
done
