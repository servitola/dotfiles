#!/usr/bin/env bash
# Clone all external skill repos listed in repos.txt.
# Idempotent: skips repos that already have a .git directory.
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f repos.txt ]]; then
  echo "repos.txt not found in $(pwd)" >&2
  exit 1
fi

while IFS='|' read -r url branch path; do
  url="${url%%[[:space:]]*}"
  [[ -z "$url" ]] && continue
  [[ "$url" == \#* ]] && continue

  branch="${branch//[[:space:]]/}"
  path="${path//[[:space:]]/}"

  if [[ -z "$branch" || -z "$path" ]]; then
    echo "[skip] malformed line: url=$url branch=$branch path=$path" >&2
    continue
  fi

  if [[ -d "$path/.git" ]]; then
    echo "[skip] $path already cloned"
    continue
  fi

  echo "[clone] $url ($branch) → $path"
  git clone --branch "$branch" "$url" "$path"
done < repos.txt
