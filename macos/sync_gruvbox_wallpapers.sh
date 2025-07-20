#!/bin/zsh
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
TEMP_DIR="/tmp/gruvbox-temp-$$"

mkdir -p "$WALLPAPERS_DIR"

API_RESPONSE=$(curl -s https://api.github.com/repos/AngelJumbo/gruvbox-wallpapers/contents/wallpapers/irl)
if echo "$API_RESPONSE" | jq -e 'type == "array"' >/dev/null 2>&1; then
    REMOTE_FILES=$(echo "$API_RESPONSE" | jq -r '.[].name' | sort)
elif echo "$API_RESPONSE" | jq -e 'has("message")' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$API_RESPONSE" | jq -r '.message')
    if echo "$ERROR_MSG" | grep -q "rate limit"; then
        echo "GitHub API rate limit reached, skipping wallpaper sync"
        exit 0
    else
        echo "GitHub API error: $ERROR_MSG"
        exit 1
    fi
else
    echo "Unexpected API response format"
    exit 1
fi
LOCAL_FILES=$(find "$WALLPAPERS_DIR" -type f -exec basename {} \; 2>/dev/null | sort)

echo "$REMOTE_FILES" > /tmp/remote_files_$$
echo "$LOCAL_FILES" > /tmp/local_files_$$
MISSING_FILES=$(comm -23 /tmp/remote_files_$$ /tmp/local_files_$$)
rm -f /tmp/remote_files_$$ /tmp/local_files_$$

[ -z "$MISSING_FILES" ] && exit 0

git clone --filter=blob:none --sparse --depth=1 https://github.com/AngelJumbo/gruvbox-wallpapers.git "$TEMP_DIR" 2>/dev/null || exit 1
cd "$TEMP_DIR" && git sparse-checkout set wallpapers/irl

echo "$MISSING_FILES" | while read -r file; do
    [ -f "$TEMP_DIR/wallpapers/irl/$file" ] && cp "$TEMP_DIR/wallpapers/irl/$file" "$WALLPAPERS_DIR/"
done

rm -rf "$TEMP_DIR"
