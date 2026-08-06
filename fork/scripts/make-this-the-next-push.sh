#!/usr/bin/env bash
. "$(dirname "$0")/lib.sh"
sha="$1"

up=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
if [ -z "$up" ]; then
  alert "Fork: no pushed point" "This branch has no upstream yet — nothing has been pushed, so there's no pushed point to move this commit above. Push the branch first."
  exit 1
fi
mb=$(git merge-base HEAD "$up" 2>/dev/null)
if [ -z "$mb" ]; then
  alert "Fork: no common base" "Could not find where this branch and its upstream ($up) diverge."
  exit 1
fi
sel=$(git rev-parse "$sha")
if ! git merge-base --is-ancestor "$sel" HEAD; then
  alert "Fork: not on this branch" "That commit is not part of the current branch's history."
  exit 1
fi
if git merge-base --is-ancestor "$sel" "$mb"; then
  alert "Fork: already pushed" "That commit is at or below the pushed point ($up) — it is already pushed. Only unpushed commits can be reordered this way."
  exit 1
fi
if [ "$(git rev-parse "$mb")" = "$(git rev-parse "$sel^" 2>/dev/null)" ]; then
  notify "Already the next commit to push — nothing to move."
  exit 0
fi
export FORK_SEL="$sel"
SEQ='f(){ t="$1.fork"; : > "$t"; p=""; while IFS= read -r ln; do kw=${ln%% *}; rest=${ln#* }; h=${rest%% *}; case "$kw" in pick|p|reword|r|edit|e|squash|s|fixup|f) case "$FORK_SEL" in "$h"*) p="$ln"; continue;; esac ;; esac; printf "%s\n" "$ln" >> "$t"; done < "$1"; if [ -n "$p" ]; then { printf "%s\n" "$p"; cat "$t"; } > "$t.2" && mv "$t.2" "$t"; fi; mv "$t" "$1"; }; f'
stashed=0
if [ -n "$(git status --porcelain)" ]; then
  if git stash push -u -m "fork:make-next-push" >/dev/null 2>&1; then
    stashed=1
  else
    alert "Fork: cannot reorder" "Could not stash your uncommitted changes — nothing was changed."
    exit 1
  fi
fi
orig=$(git rev-parse HEAD)
ok=0
attempt=0
while [ "$attempt" -lt 8 ]; do
  attempt=$((attempt + 1))
  waitlock
  if GIT_SEQUENCE_EDITOR="$SEQ" GIT_EDITOR=true git rebase -i "$mb" >/dev/null 2>&1; then
    ok=1
    break
  fi
  git rebase --abort >/dev/null 2>&1
  waitlock
  git reset --hard "$orig" >/dev/null 2>&1
  sleep 0.3
done
if [ "$ok" -ne 1 ]; then
  [ "$stashed" = 1 ] && git stash pop >/dev/null 2>&1
  alert "Fork: reorder failed" "Could not move this commit above the pushed point — most likely reordering it there causes a conflict. Your branch and changes are untouched."
  exit 1
fi
if [ "$stashed" = 1 ]; then
  git stash pop >/dev/null 2>&1 || alert "Fork: heads up" "Commit moved. Your uncommitted changes stayed safe in the stash (git stash list)."
fi
notify "Moved — this is now the next commit to push."
exit 0
