#!/usr/bin/env bash
# The solution nearest to the repository root; without one Rider opens the folder.
repo="$1"

target=$(find "$repo" -maxdepth 2 \( -name '*.sln' -o -name '*.slnx' \) \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/bin/*' -not -path '*/obj/*' \
  | awk -F/ '{ print NF "\t" $0 }' | sort -n -k1,1 -k2 | head -1 | cut -f2)

# -l: Fork starts scripts without the login PATH, where the rider launcher lives.
zsh -lc 'rider "$1"' _ "${target:-$repo}"
