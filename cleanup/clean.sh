#!/bin/zsh
# where_is_my_space — bootstrap for curl | zsh
# curl -fsSL https://raw.githubusercontent.com/servitola/dotfiles/master/cleanup/clean.sh | zsh

set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/servitola/dotfiles/master/cleanup"
TMPDIR_CLEANUP=$(mktemp -d)
trap "rm -rf $TMPDIR_CLEANUP" EXIT

printf '\033[0;92m\033[1mwhere_is_my_space\033[0m — downloading cleanup scripts...\n'

curl -fsSL "$REPO_BASE/helpers.sh"          -o "$TMPDIR_CLEANUP/helpers.sh"
curl -fsSL "$REPO_BASE/try_clean.sh"        -o "$TMPDIR_CLEANUP/try_clean.sh"
curl -fsSL "$REPO_BASE/cleanup_targets.sh"  -o "$TMPDIR_CLEANUP/cleanup_targets.sh"
curl -fsSL "$REPO_BASE/cleanup_all.sh"      -o "$TMPDIR_CLEANUP/cleanup_all.sh"

chmod +x "$TMPDIR_CLEANUP"/*.sh

CLEANUP_DIR="$TMPDIR_CLEANUP" source "$TMPDIR_CLEANUP/cleanup_all.sh"
