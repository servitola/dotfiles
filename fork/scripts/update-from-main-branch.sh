#!/usr/bin/env bash

main=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
if [ -z "$main" ]; then
  git remote set-head origin -a >/dev/null 2>&1
  main=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
fi
[ -z "$main" ] && main=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
[ -z "$main" ] && main=Development
git fetch origin --prune >/dev/null 2>&1
out=$(git rebase --autostash "origin/$main" 2>&1) || {
  git rebase --abort >/dev/null 2>&1
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: rebase conflict" message (item 1 of argv) as critical' -e 'end run' "Rebase onto origin/$main hit a conflict. Aborted — your branch is unchanged.

$out"
  exit 1
}
/usr/bin/osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Fork"' -e 'end run' "Rebased onto origin/$main"
exit 0
