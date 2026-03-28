#!/bin/zsh
# Download a single wallpaper from URL
# Usage: download_wallpaper.sh <url> <output_path> <name_for_blocklist>
# Used by Hammerspoon GruvboxWallpapers.spoon

set -e

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <url> <output_path> <name_for_blocklist>" >&2
    exit 1
fi

URL="$1"
OUTPUT="$2"
WALLPAPER_NAME="$3"
WALLPAPERS_DIR="$(dirname "$OUTPUT")"
BLOCKLIST="$HOME/projects/dotfiles/macos/wallpapers-blocklist.txt"

CURL_OPTS=(-s --noproxy '*')
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

mkdir -p "$WALLPAPERS_DIR"

# Download to temp file first
TEMP_FILE=$(mktemp)
trap "rm -f '$TEMP_FILE'" EXIT

if ! /usr/bin/curl -L "${CURL_OPTS[@]}" -o "$TEMP_FILE" "$URL"; then
    echo "ERROR: Download failed" >&2
    exit 1
fi

# Validate resolution (minimum 3840x2160)
read w h < <(sips -g pixelWidth -g pixelHeight "$TEMP_FILE" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w, h}')
if (( w < 3840 || h < 2160 )); then
    echo "ERROR: Resolution too low (${w}x${h}), minimum 3840x2160" >&2
    # Add to blocklist
    echo "$WALLPAPER_NAME" >> "$BLOCKLIST"
    echo "BLOCKLIST:$WALLPAPER_NAME"
    exit 1
fi

# Move to final location
mv "$TEMP_FILE" "$OUTPUT"
echo "$OUTPUT"
