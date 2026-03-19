#!/bin/zsh
# Fetch ALL available wallpaper URLs from configured repositories
# Outputs: JSON array of {name, url} objects, shuffled randomly
# Used by Hammerspoon GruvboxWallpapers.spoon

BLOCKLIST="$HOME/projects/dotfiles/macos/wallpapers-blocklist.txt"

CURL_OPTS=(-s --noproxy '*')
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

# repos: "owner/repo|path"  (path empty = root files only, path set = has category subdirs)
REPOS=(
    "AngelJumbo/gruvbox-wallpapers|wallpapers"
    "Nix3l/gruvbox-bgs|"
    "dharmx/walls|."
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

# Collect all name\turl pairs
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
            CATEGORY_ENCODED=$(printf '%s' "$CATEGORY" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
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

# Filter out blocklisted wallpapers, output as shuffled JSON array
{
    for entry in "${WALLPAPERS[@]}"; do
        name="${entry%%	*}"
        url="${entry#*	}"
        if [[ -f "$BLOCKLIST" ]] && grep -qxF "$name" "$BLOCKLIST"; then
            continue
        fi
        printf '%s\t%s\n' "$name" "$url"
    done
} | shuf | jq -Rnc '[inputs | split("\t") | {name: .[0], url: .[1]}]'
