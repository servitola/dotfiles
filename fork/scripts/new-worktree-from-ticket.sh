#!/usr/bin/env bash
repo="$1"

name=$(basename "$repo")
parent=$(dirname "$repo")
wtroot="$parent/${name}-worktrees"
ticket=$(/usr/bin/osascript -e 'text returned of (display dialog "YouTrack ticket + optional slug (e.g. ABC-123 add login):" default answer "")' 2>/dev/null) || exit 0
branch=$(printf '%s' "$ticket" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/-+/-/g; s/^-+|-+$//g')
[ -z "$branch" ] && exit 0
git -C "$repo" fetch origin --prune >/dev/null 2>&1
main=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
if [ -z "$main" ]; then
  git -C "$repo" remote set-head origin -a >/dev/null 2>&1
  main=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
fi
[ -z "$main" ] && main=Development
dest="$wtroot/$branch"
if [ -e "$dest" ]; then
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: worktree exists" message (item 1 of argv) as critical' -e 'end run' "$dest already exists."
  exit 1
fi
mkdir -p "$wtroot"
out=$(git -C "$repo" worktree add "$dest" -b "$branch" --no-track "origin/$main" 2>&1) || {
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: worktree failed" message (item 1 of argv) as critical' -e 'end run' "$out"
  exit 1
}
open -a Fork "$dest"
exit 0
