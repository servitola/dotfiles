#!/bin/zsh

function mkd() {
    mkdir -p "$@" && cd "$_"
}

# cd to git repo root
function groot() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repository" >&2; return 1; }
    cd "$root"
}

# get macOS app Bundle ID and copy to clipboard
function bundleid() {
    local id=$(osascript -e "id of app \"$1\"" 2>/dev/null)
    if [[ -n "$id" ]]; then
        echo "$id" | tr -d '\n' | pbcopy
        echo "$id (copied)"
    else
        echo "App not found: $1"
        return 1
    fi
}
