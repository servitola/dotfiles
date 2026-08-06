#!/usr/bin/env bash
. "$(dirname "$0")/lib.sh"
sha="$1"

D=$(/usr/bin/osascript -e 'on run argv' -e 'text returned of (display dialog "Commit time (YYYY-MM-DD HH:MM:SS):" default answer (item 1 of argv))' -e 'end run' "$(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null) || exit 0
[ -z "$D" ] && exit 0
stashed=0
if [ -n "$(git status --porcelain)" ]; then
  if git stash push -u -m "fork:set-time" >/dev/null 2>&1; then
    stashed=1
  else
    alert "Fork: cannot set time" "Could not stash your uncommitted changes — nothing was changed."
    exit 1
  fi
fi
orig=$(git rev-parse HEAD)
ok=0
attempt=0
while [ "$attempt" -lt 8 ]; do
  attempt=$((attempt + 1))
  waitlock
  if GIT_SEQUENCE_EDITOR='sed -i "" "1s/^pick /edit /"' git rebase -i --committer-date-is-author-date "$sha^" >/dev/null 2>&1; then
    waitlock
    if GIT_COMMITTER_DATE="$D" git commit --amend --no-edit --date="$D" >/dev/null 2>&1; then
      waitlock
      if GIT_EDITOR=true git rebase --continue >/dev/null 2>&1; then
        ok=1; break
      fi
    fi
  fi
  git rebase --abort >/dev/null 2>&1
  waitlock
  git reset --hard "$orig" >/dev/null 2>&1
  sleep 0.3
done
if [ "$ok" -ne 1 ]; then
  [ "$stashed" = 1 ] && git stash pop >/dev/null 2>&1
  alert "Fork: set time failed" "Could not set the commit time (bad date, or git stayed busy). Your branch and changes are untouched."
  exit 1
fi
if [ "$stashed" = 1 ]; then
  git stash pop >/dev/null 2>&1 || alert "Fork: heads up" "Time set. Your uncommitted changes stayed safe in the stash (git stash list)."
fi
exit 0
