#!/bin/zsh
# Fetch a random wallpaper URL from configured repositories
# Picks random repo → random subdir → random image (2-3 API calls)
# Outputs: JSON array of {name, url} objects (candidates from one directory)
# Used by Hammerspoon GruvboxWallpapers.spoon

BLOCKLIST="$HOME/Pictures/Wallpapers/GruvBox/blocklist.txt"
HISTORY="$HOME/Pictures/Wallpapers/GruvBox/history.log"

CURL_OPTS=(-s --noproxy '*')
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

# repos: "owner/repo|path"  (path empty = root files only, path set = has category subdirs)
REPOS=(
    "AngelJumbo/gruvbox-wallpapers|wallpapers"
    "Nix3l/gruvbox-bgs|"
    "dharmx/walls|."
    "makccr/wallpapers|wallpapers"
    "Ajaymanikandan0x/hyprland_wallpapers|"
)

fetch_json() {
    /usr/bin/curl -sL "${CURL_OPTS[@]}" "https://api.github.com/repos/$1/contents/$2"
}

check_rate_limit() {
    if echo "$1" | jq -e 'has("message")' > /dev/null 2>&1; then
        local msg=$(echo "$1" | jq -r '.message')
        echo "API error [$2]: $msg" >&2
        return 1
    fi
    return 0
}

# Pick a random repo
REPO_ENTRY="${REPOS[$((RANDOM % ${#REPOS[@]} + 1))]}"
OWNER_REPO="${REPO_ENTRY%%|*}"
ROOT_PATH="${REPO_ENTRY#*|}"

# For repos with subdirs, pick a random subdirectory
API_PATH="$ROOT_PATH"
if [[ -n "$ROOT_PATH" ]]; then
    ROOT_RESPONSE=$(fetch_json "$OWNER_REPO" "$ROOT_PATH")
    check_rate_limit "$ROOT_RESPONSE" "$OWNER_REPO" || exit 1

    CATEGORIES=($(echo "$ROOT_RESPONSE" | jq -r '.[] | select(.type=="dir") | .name'))
    if [[ ${#CATEGORIES[@]} -eq 0 ]]; then
        echo "ERROR: no subdirectories found in $OWNER_REPO/$ROOT_PATH" >&2
        exit 1
    fi
    CATEGORY="${CATEGORIES[$((RANDOM % ${#CATEGORIES[@]} + 1))]}"
    API_PATH="$ROOT_PATH/$(printf '%s' "$CATEGORY" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")"
fi

# Fetch images from the chosen directory
API_RESPONSE=$(fetch_json "$OWNER_REPO" "$API_PATH")
check_rate_limit "$API_RESPONSE" "$OWNER_REPO/$API_PATH" || exit 1

# Filter to images, exclude blocklisted, shuffle, output as JSON
echo "$API_RESPONSE" | jq -r '.[] | select(.type=="file") | [.name, .download_url] | @tsv' \
    | grep -iE '\.(png|jpg|jpeg|webp|heic)$' \
    | while IFS=$'\t' read -r name url; do
        name="${name#_}"
        if [[ -f "$BLOCKLIST" ]] && grep -qxF "$name" "$BLOCKLIST"; then
            continue
        fi
        if [[ -f "$HISTORY" ]] && grep -qxF "$name" "$HISTORY"; then
            continue
        fi
        printf '%s\t%s\n' "$name" "$url"
    done \
    | sort -R \
    | jq -Rnc '[inputs | split("\t") | {name: .[0], url: .[1]}]'
