#!/usr/bin/env bash
. "$(dirname "$0")/lib.sh"
sha="$1"

short=$(git rev-parse --short "$sha")
subject=$(git log -1 --format=%s "$sha")
btn=$(/usr/bin/osascript -e 'on run argv' -e 'button returned of (display dialog "Force-drop " & (item 1 of argv) & " — " & (item 2 of argv) & "?" & return & "Rewrites history; conflicts resolve in favor of the drop." buttons {"Cancel","Drop"} default button "Cancel" with icon caution)' -e 'end run' "$short" "$subject" 2>/dev/null) || exit 0
[ "$btn" = "Drop" ] || exit 0
stashed=0
if [ -n "$(git status --porcelain)" ]; then
  if git stash push -u -m "fork:drop-commit" >/dev/null 2>&1; then
    stashed=1
  else
    alert "Fork: cannot drop commit" "Could not stash your uncommitted changes — nothing was changed."
    exit 1
  fi
fi
orig=$(git rev-parse HEAD)
ok=0
attempt=0
while [ "$attempt" -lt 8 ]; do
  attempt=$((attempt + 1))
  waitlock
  git rebase --onto "$sha^" "$sha" -X ours >/dev/null 2>&1
  rc=$?
  tries=0
  while [ "$rc" -ne 0 ] && { [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; } && [ "$tries" -lt 500 ]; do
    waitlock
    git checkout --ours -- . >/dev/null 2>&1
    git add -A >/dev/null 2>&1
    if git diff --cached --quiet >/dev/null 2>&1; then
      GIT_EDITOR=true git rebase --skip >/dev/null 2>&1
    else
      GIT_EDITOR=true git rebase --continue >/dev/null 2>&1
    fi
    rc=$?
    tries=$((tries + 1))
  done
  if [ "$rc" -eq 0 ]; then ok=1; break; fi
  git rebase --abort >/dev/null 2>&1
  waitlock
  git reset --hard "$orig" >/dev/null 2>&1
  sleep 0.3
done
if [ "$ok" -ne 1 ]; then
  [ "$stashed" = 1 ] && git stash pop >/dev/null 2>&1
  alert "Fork: drop failed" "Could not drop this commit (git stayed busy). Your branch and changes are untouched."
  exit 1
fi
if [ "$stashed" = 1 ]; then
  git stash pop >/dev/null 2>&1 || alert "Fork: heads up" "Commit dropped. Your uncommitted changes stayed safe in the stash (git stash list)."
fi
exit 0
