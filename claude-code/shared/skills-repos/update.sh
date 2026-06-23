#!/usr/bin/env bash
# Fast-forward pull each repo listed in repos.txt.
# - Pulls the CURRENT branch of each clone (not the manifest branch),
#   so locally checked-out feature branches keep working.
# - --ff-only means a dirty tree or diverged history skips with a warning
#   instead of clobbering work.
set -uo pipefail

cd "$(dirname "$0")" || exit 1

if [[ ! -f repos.txt ]]; then
  echo "repos.txt not found in $(pwd)" >&2
  exit 1
fi

# manifest line format: url|branch|path — branch is ignored here (we pull
# whatever branch each clone has checked out), hence the `_` placeholder
while IFS='|' read -r url _ path; do
  url="${url%%[[:space:]]*}"
  [[ -z "$url" ]] && continue
  [[ "$url" == \#* ]] && continue

  path="${path//[[:space:]]/}"
  [[ -z "$path" ]] && continue

  if [[ ! -d "$path/.git" ]]; then
    echo "[miss]  $path — run install.sh"
    continue
  fi

  current_branch=$(git -C "$path" symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
  echo "[pull]  $path ($current_branch)"
  if ! git -C "$path" pull --ff-only --quiet; then
    echo "[warn]  $path: pull skipped (dirty tree, diverged, or no upstream)"
  fi
done < repos.txt
