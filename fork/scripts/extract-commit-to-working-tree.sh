#!/usr/bin/env bash
sha="$1"

stashed=0
if [ -n "$(git status --porcelain)" ]; then
  if git stash push -u -m "fork:extract-commit" >/dev/null 2>&1; then
    stashed=1
  else
    /usr/bin/osascript -e 'display alert "Fork: cannot extract commit" message "Could not stash your uncommitted changes — nothing was changed." as critical'
    exit 1
  fi
fi
orig=$(git rev-parse HEAD)
out=$(git rebase --onto "$sha^" "$sha" 2>&1) || {
  git rebase --abort >/dev/null 2>&1
  [ "$stashed" = 1 ] && git stash pop >/dev/null 2>&1
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: cannot extract commit" message (item 1 of argv) as critical' -e 'end run' "Moving this commit to the top would conflict with the other commits. Your branch and changes are untouched, nothing lost.

$out"
  exit 1
}
out=$(git cherry-pick "$sha" 2>&1) || {
  git cherry-pick --abort >/dev/null 2>&1
  git reset --hard "$orig" >/dev/null 2>&1
  [ "$stashed" = 1 ] && git stash pop >/dev/null 2>&1
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: cannot extract commit" message (item 1 of argv) as critical' -e 'end run' "This commit does not apply cleanly on top. Your branch and changes are untouched, nothing lost.

$out"
  exit 1
}
git reset --mixed HEAD~1 >/dev/null 2>&1
if [ "$stashed" = 1 ]; then
  git stash pop >/dev/null 2>&1 || /usr/bin/osascript -e 'display alert "Fork: heads up" message "Commit extracted to the working tree. Your earlier uncommitted changes overlapped and stayed in the stash (git stash list)." as critical'
fi
exit 0
