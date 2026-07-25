#!/usr/bin/env bash
# Is this typeface available on this machine?
#
#   font-check.sh "Garamond"      → matching installed families
#   font-check.sh --list          → every installed family
#
# A recommendation the user cannot render is worthless, so check before proposing.
# Needs fontconfig (brew install fontconfig) — fails loudly if it is missing.

set -euo pipefail

families() { fc-list : family | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u | grep -v '^$'; }

if [[ "${1:-}" == "--list" ]]; then
  families
  exit 0
fi

if [[ $# -eq 0 ]]; then
  echo "usage: font-check.sh <family name> | --list" >&2
  exit 2
fi

query="$*"
matches=$(families | grep -i -- "$query" || true)

if [[ -n "$matches" ]]; then
  printf 'installed, matching "%s":\n' "$query"
  printf '%s\n' "$matches" | sed 's/^/  /'
  printf '\nstyles:\n'
  fc-list -f '%{family[0]} — %{style[0]}\n' | grep -i -- "$query" | sort -u | sed 's/^/  /'
else
  printf 'not installed: "%s"\n' "$query"
  printf 'pick a substitute from references/catalog.md, or use a webfont.\n'
  printf 'nearest installed families by name:\n'
  families | grep -i -- "${query%% *}" | head -5 | sed 's/^/  /' || true
fi
