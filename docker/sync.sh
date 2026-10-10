#!/bin/zsh
# Lists running compose stacks that neither registry knows, to add by hand with
# their machines. It no longer rewrites the registry: only a person knows where a stack belongs.
set -eu
registered=$(grep -hv '^#' "$HOME/projects/dotfiles/docker/compose-projects.txt" \
    "$HOME/projects/dotfiles/docker/compose-projects.private.txt" | awk '{print $1}')
docker compose ls --format json | jq -r '.[].ConfigFiles' | tr ',' '\n' | xargs -n1 dirname | sort -u \
    | while read -r dir; do
        relative=${dir#$HOME/}
        print -l -- $registered | grep -qxF -e "$relative" -e "$dir" || print "not registered: $relative"
    done
