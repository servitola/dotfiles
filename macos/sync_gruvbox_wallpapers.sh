#!/bin/zsh
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
TEMP_DIR="/tmp/gruvbox-temp-$$"

mkdir -p "$WALLPAPERS_DIR"

CURL_OPTS=(-s)
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

# Directories to sync from the repository
CATEGORIES=("photography" "pixelart", "mix", "minimalistic")
ALL_REMOTE_FILES=""

# Fetch file lists from all categories
for CATEGORY in "${CATEGORIES[@]}"; do
    API_RESPONSE=$(curl "${CURL_OPTS[@]}" \
        "https://api.github.com/repos/AngelJumbo/gruvbox-wallpapers/contents/wallpapers/$CATEGORY")

    if echo "$API_RESPONSE" | jq -e 'type == "array"' > /dev/null 2>&1; then
        REMOTE_FILES=$(echo "$API_RESPONSE" | jq -r '.[].name' | sort)
        ALL_REMOTE_FILES="${ALL_REMOTE_FILES}${REMOTE_FILES}"$'\n'
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

ALL_REMOTE_FILES=$(echo "$ALL_REMOTE_FILES" | sort -u)
LOCAL_FILES=$(find "$WALLPAPERS_DIR" -type f -exec basename {} \; 2> /dev/null | sort)

echo "$ALL_REMOTE_FILES" > /tmp/remote_files_$$
echo "$LOCAL_FILES" > /tmp/local_files_$$
MISSING_FILES=$(comm -23 /tmp/remote_files_$$ /tmp/local_files_$$)
rm -f /tmp/remote_files_$$ /tmp/local_files_$$

[ -z "$MISSING_FILES" ] && exit 0

git clone --filter=blob:none --sparse --depth=1 \
    https://github.com/AngelJumbo/gruvbox-wallpapers.git "$TEMP_DIR" 2> /dev/null || exit 1
cd "$TEMP_DIR" && git sparse-checkout set wallpapers/photography wallpapers/pixelart wallpapers/mix wallpapers/minimalistic

echo "$MISSING_FILES" | while read -r file; do
    for CATEGORY in "${CATEGORIES[@]}"; do
        if [ -f "$TEMP_DIR/wallpapers/$CATEGORY/$file" ]; then
            cp "$TEMP_DIR/wallpapers/$CATEGORY/$file" "$WALLPAPERS_DIR/"
            break
        fi
    done
done

rm -rf "$TEMP_DIR"
