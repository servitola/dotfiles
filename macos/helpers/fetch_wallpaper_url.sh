#!/bin/zsh
# Fetch a single random wallpaper URL from gruvbox repositories
# Outputs: download_url for a random filtered wallpaper
# Used by Hammerspoon GruvboxWallpapers.spoon

BLOCKLIST="$HOME/projects/dotfiles/macos/wallpapers-blocklist.txt"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers/GruvBox"

CURL_OPTS=(-s --noproxy '*')
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

# repos: "owner/repo|path"  (path empty = root, path set = has category subdirs)
REPOS=(
    "AngelJumbo/gruvbox-wallpapers|wallpapers"
    "Nix3l/gruvbox-bgs|"
)

fetch_files() {
    local owner_repo="$1"
    local path="$2"
    /usr/bin/curl -sL "${CURL_OPTS[@]}" "https://api.github.com/repos/$owner_repo/contents/$path"
}

is_image() {
    [[ "$1" =~ \.(png|jpg|jpeg|gif|webp|heic)$ ]]
}

check_rate_limit() {
    local response="$1"
    local context="$2"
    if echo "$response" | jq -e 'has("message")' > /dev/null 2>&1; then
        local msg=$(echo "$response" | jq -r '.message')
        if echo "$msg" | grep -q "rate limit"; then
            echo "ERROR: GitHub API rate limit reached" >&2
            exit 1
        fi
        echo "API error [$context]: $msg" >&2
        return 1
    fi
    return 0
}

collect_images() {
    local api_response="$1"
    echo "$api_response" | jq -r '.[] | select(.type=="file") | [.name, .download_url] | @tsv'
}

# Collect all name|url pairs into a plain array
WALLPAPERS=()

for repo_entry in "${REPOS[@]}"; do
    OWNER_REPO="${repo_entry%%|*}"
    ROOT_PATH="${repo_entry#*|}"

    if [[ -n "$ROOT_PATH" ]]; then
        # repo has category subdirectories — fetch them dynamically
        ROOT_RESPONSE=$(fetch_files "$OWNER_REPO" "$ROOT_PATH")
        check_rate_limit "$ROOT_RESPONSE" "$OWNER_REPO" || continue

        CATEGORIES=()
        while IFS= read -r line; do
            CATEGORIES+=("$line")
        done < <(echo "$ROOT_RESPONSE" | jq -r '.[] | select(.type=="dir") | .name')

        for CATEGORY in "${CATEGORIES[@]}"; do
            CATEGORY_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CATEGORY'))")
            API_RESPONSE=$(fetch_files "$OWNER_REPO" "$ROOT_PATH/$CATEGORY_ENCODED")
            check_rate_limit "$API_RESPONSE" "$OWNER_REPO/$CATEGORY" || continue

            if echo "$API_RESPONSE" | jq -e 'type == "array"' > /dev/null 2>&1; then
                while IFS=$'\t' read -r name download_url; do
                    is_image "$name" || continue
                    name="${name#_}"
                    WALLPAPERS+=("${name}	${download_url}")
                done < <(collect_images "$API_RESPONSE")
            fi
        done
    else
        # flat repo — files at root
        API_RESPONSE=$(fetch_files "$OWNER_REPO" "")
        check_rate_limit "$API_RESPONSE" "$OWNER_REPO" || continue

        if echo "$API_RESPONSE" | jq -e 'type == "array"' > /dev/null 2>&1; then
            while IFS=$'\t' read -r name download_url; do
                is_image "$name" || continue
                name="${name#_}"
                WALLPAPERS+=("${name}	${download_url}")
            done < <(collect_images "$API_RESPONSE")
        fi
    fi
done

# Filter out blocklisted wallpapers
FILTERED=()
for entry in "${WALLPAPERS[@]}"; do
    name="${entry%%	*}"
    if [[ -f "$BLOCKLIST" ]] && grep -qxF "$name" "$BLOCKLIST"; then
        continue
    fi
    FILTERED+=("$entry")
done

if [[ ${#FILTERED[@]} -eq 0 ]]; then
    echo "ERROR: No wallpapers available after filtering" >&2
    exit 1
fi

# Select random wallpaper
RANDOM_INDEX=$((RANDOM % ${#FILTERED[@]}))
SELECTED="${FILTERED[$RANDOM_INDEX]}"
SELECTED_NAME="${SELECTED%%	*}"
SELECTED_URL="${SELECTED#*	}"

# Output as JSON for easy parsing
echo "{\"name\": \"$SELECTED_NAME\", \"url\": \"$SELECTED_URL\"}"
