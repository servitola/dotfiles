#!/usr/bin/env bash
sha="$1"
repo="$2"
# Третий аргумент приходит только от reference-варианта команды: там Fork уже
# знает ветку ($name, «origin/foo» для удалённой), и гадать по коммиту не надо.
ref="$3"

name=$(basename "$repo")
parent=$(dirname "$repo")
wtroot="$parent/${name}-worktrees"

if [ -n "$ref" ]; then
  cands="$ref"
else
  cands=$(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads --points-at "$sha")
  [ -z "$cands" ] && cands=$(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads --contains "$sha")
  [ -z "$cands" ] && cands=$(git -C "$repo" for-each-ref --format='%(refname:short)' refs/remotes --points-at "$sha" | grep -vE '/HEAD$')
  [ -z "$cands" ] && cands=$(git -C "$repo" for-each-ref --format='%(refname:short)' refs/remotes --contains "$sha" | grep -vE '/HEAD$')
fi
if [ -z "$cands" ]; then
  /usr/bin/osascript -e 'display alert "Fork: no branch" message "No local or remote branch points at or contains this commit." as critical'
  exit 1
fi
count=$(printf '%s\n' "$cands" | grep -c .)
if [ "$count" -eq 1 ]; then
  sel=$(printf '%s' "$cands" | head -1)
else
  sel=$(/usr/bin/osascript -e 'on run argv' -e 'set L to paragraphs of (item 1 of argv)' -e 'set c to (choose from list L with prompt "Which branch to open in a worktree?")' -e 'if c is false then return ""' -e 'return item 1 of c' -e 'end run' "$cands") || exit 0
  [ -z "$sel" ] && exit 0
fi
if git -C "$repo" show-ref --verify --quiet "refs/remotes/$sel"; then
  branch=$(printf '%s' "$sel" | sed 's#^[^/]*/##')
  remoteref="$sel"
else
  branch="$sel"
  remoteref=""
fi
slug=$(printf '%s' "$branch" | sed -E 's#[/ ]+#-#g')
dest="$wtroot/$slug"
if [ -e "$dest" ]; then
  open -a Fork "$dest"
  exit 0
fi
mkdir -p "$wtroot"
if [ -n "$remoteref" ] && ! git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
  # Защищённую ветку никогда не делаем upstream'ом: случайный `git push` из
  # воркдерева ушёл бы прямо в неё.
  case "$branch" in
    Development|development|main|master|trunk) track="--no-track" ;;
    *) track="--track" ;;
  esac
  out=$(git -C "$repo" worktree add $track -b "$branch" "$dest" "$remoteref" 2>&1) || {
    /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: worktree failed" message (item 1 of argv) as critical' -e 'end run' "$out"
    exit 1
  }
else
  out=$(git -C "$repo" worktree add "$dest" "$branch" 2>&1) || {
    /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: worktree failed" message (item 1 of argv) as critical' -e 'end run' "$out"
    exit 1
  }
fi
open -a Fork "$dest"
exit 0
