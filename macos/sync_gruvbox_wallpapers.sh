#!/bin/zsh
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

mkdir -p "$WALLPAPERS_DIR"

CURL_OPTS=(-s --noproxy '*')
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

CATEGORIES=("photography" "pixelart" "mix" "minimalistic")

# Fetch file lists and download URLs from all categories
declare -A DOWNLOAD_URLS
for CATEGORY in "${CATEGORIES[@]}"; do
    API_RESPONSE=$(curl "${CURL_OPTS[@]}" \
        "https://api.github.com/repos/AngelJumbo/gruvbox-wallpapers/contents/wallpapers/$CATEGORY")

    if echo "$API_RESPONSE" | jq -e 'type == "array"' > /dev/null 2>&1; then
        while IFS=$'\t' read -r name url; do
            DOWNLOAD_URLS[$name]=$url
        done < <(echo "$API_RESPONSE" | jq -r '.[] | [.name, .download_url] | @tsv')
    elif echo "$API_RESPONSE" | jq -e 'has("message")' > /dev/null 2>&1; then
        ERROR_MSG=$(echo "$API_RESPONSE" | jq -r '.message')
        if echo "$ERROR_MSG" | grep -q "rate limit"; then
            echo "GitHub API rate limit reached, skipping wallpaper sync"
            exit 0
        else
            echo "GitHub API error for $CATEGORY: $ERROR_MSG"
            continue
        fi
    else
        echo "Unexpected API response format for $CATEGORY"
        continue
    fi
done

LOCAL_FILES=$(find "$WALLPAPERS_DIR" -type f -exec basename {} \; 2>/dev/null | sort)

MISSING=0
for name url in "${(@kv)DOWNLOAD_URLS}"; do
    if ! echo "$LOCAL_FILES" | grep -qF "$name"; then
        if [ $MISSING -eq 0 ]; then
            echo "⬇ Downloading missing wallpapers..."
        fi
        curl "${CURL_OPTS[@]}" -o "$WALLPAPERS_DIR/$name" "$url" && echo "  + $name"
        MISSING=$((MISSING + 1))
    fi
done

[ $MISSING -eq 0 ] && echo "✓ Wallpapers up to date" || echo "✓ Wallpapers synced ($MISSING new)"
