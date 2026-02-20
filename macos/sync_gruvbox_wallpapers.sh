#!/bin/zsh
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
TEMP_DIR="/tmp/gruvbox-temp-$$"
GIT_REPO_DIR="$HOME/.cache/gruvbox-wallpapers"

mkdir -p "$WALLPAPERS_DIR"

CURL_OPTS=(-s)
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

# Directories to sync from the repository
CATEGORIES=("photography" "pixelart" "mix" "minimalistic")
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

[ -z "$MISSING_FILES" ] && echo "✓ Wallpapers up to date" && exit 0

echo "⬇ Downloading missing wallpapers..."

# Clone or update cached repository
if [ -d "$GIT_REPO_DIR/.git" ]; then
    cd "$GIT_REPO_DIR" && git fetch origin --depth=1 > /dev/null 2>&1
else
    mkdir -p "$GIT_REPO_DIR"
    git clone --filter=blob:none --sparse --depth=1 \
        https://github.com/AngelJumbo/gruvbox-wallpapers.git "$GIT_REPO_DIR" 2> /dev/null || exit 1
    cd "$GIT_REPO_DIR" && git sparse-checkout set wallpapers/photography wallpapers/pixelart wallpapers/mix wallpapers/minimalistic > /dev/null 2>&1
fi

echo "$MISSING_FILES" | while read -r file; do
    for CATEGORY in "${CATEGORIES[@]}"; do
        if [ -f "$GIT_REPO_DIR/wallpapers/$CATEGORY/$file" ]; then
            cp "$GIT_REPO_DIR/wallpapers/$CATEGORY/$file" "$WALLPAPERS_DIR/"
            break
        fi
    done
done

echo "✓ Wallpapers synced"
