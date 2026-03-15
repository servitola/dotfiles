#!/bin/zsh
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers/GruvBox"
BLOCKLIST="$HOME/projects/dotfiles/macos/wallpapers-blocklist.txt"

mkdir -p "$WALLPAPERS_DIR"

CURL_OPTS=(-s --noproxy '*')
[ -n "$GITHUB_API_TOKEN" ] && CURL_OPTS+=(-H "Authorization: token $GITHUB_API_TOKEN")

SHA_CACHE="$WALLPAPERS_DIR/.repo_shas"
touch "$SHA_CACHE"

fetch_sha() {
    local owner_repo="$1"
    /usr/bin/curl -sL "${CURL_OPTS[@]}" "https://api.github.com/repos/$owner_repo/commits?per_page=1" \
        | jq -r '.[0].sha // empty'
}

repo_changed() {
    local owner_repo="$1"
    local sha
    sha=$(fetch_sha "$owner_repo") || return 0
    [[ -z "$sha" ]] && return 0
    local cached
    cached=$(grep "^$owner_repo " "$SHA_CACHE" | awk '{print $2}')
    [[ "$sha" != "$cached" ]]
}

update_sha_cache() {
    local owner_repo="$1"
    local sha
    sha=$(grep "^$owner_repo " "$SHA_CACHE" 2>/dev/null | awk '{print $2}')
    # re-fetch to get current sha after processing
    local new_sha
    new_sha=$(fetch_sha "$owner_repo")
    [[ -z "$new_sha" ]] && return
    # update or insert
    if grep -q "^$owner_repo " "$SHA_CACHE" 2>/dev/null; then
        sed -i '' "s|^$owner_repo .*|$owner_repo $new_sha|" "$SHA_CACHE"
    else
        echo "$owner_repo $new_sha" >> "$SHA_CACHE"
    fi
}

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
            echo "GitHub API rate limit reached, skipping wallpaper sync"
            exit 0
        fi
        echo "API error [$context]: $msg"
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

    if ! repo_changed "$OWNER_REPO"; then
        echo "✓ $OWNER_REPO unchanged"
        continue
    fi

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

    update_sha_cache "$OWNER_REPO"
done

LOCAL_FILES=$(find "$WALLPAPERS_DIR" -type f -exec basename {} \; 2>/dev/null | sort)

MISSING=0
for entry in "${WALLPAPERS[@]}"; do
    name="${entry%%	*}"
    url="${entry#*	}"

    if [[ -f "$BLOCKLIST" ]] && grep -qxF "$name" "$BLOCKLIST"; then
        continue
    fi
    if ! echo "$LOCAL_FILES" | grep -qF "$name"; then
        if [ $MISSING -eq 0 ]; then
            echo "⬇ Downloading missing wallpapers..."
        fi
        /usr/bin/curl -L "${CURL_OPTS[@]}" -o "$WALLPAPERS_DIR/$name" "$url" || continue
        read w h < <(sips -g pixelWidth -g pixelHeight "$WALLPAPERS_DIR/$name" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w, h}')
        if (( w < 3840 || h < 2160 )); then
            rm "$WALLPAPERS_DIR/$name"
            continue
        fi
        echo "  + $name (${w}x${h})"
        MISSING=$((MISSING + 1))
    fi
done

[ $MISSING -eq 0 ] && echo "✓ Wallpapers up to date" || echo "✓ Wallpapers synced ($MISSING new)"

# Deduplicate by content hash — keep longest filename, blocklist and delete the rest
DUPES_REMOVED=0
declare -A hash_to_file
while IFS= read -r file; do
    hash=$(md5 -q "$file")
    if [[ -n "${hash_to_file[$hash]}" ]]; then
        existing="${hash_to_file[$hash]}"
        existing_name=$(basename "$existing")
        new_name=$(basename "$file")
        # Keep whichever has the longer filename
        if (( ${#new_name} >= ${#existing_name} )); then
            to_delete="$existing"
            hash_to_file[$hash]="$file"
        else
            to_delete="$file"
        fi
        del_name=$(basename "$to_delete")
        echo "  - duplicate removed: $del_name"
        echo "$del_name" >> "$BLOCKLIST"
        rm "$to_delete"
        DUPES_REMOVED=$((DUPES_REMOVED + 1))
    else
        hash_to_file[$hash]="$file"
    fi
done < <(find "$WALLPAPERS_DIR" -type f | sort)
[ $DUPES_REMOVED -gt 0 ] && echo "✓ Removed $DUPES_REMOVED duplicate(s)"
exit 0
