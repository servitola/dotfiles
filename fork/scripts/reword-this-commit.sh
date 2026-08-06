#!/usr/bin/env bash
sha="$1"

cur=$(git log -1 --format=%s "$sha")
new=$(/usr/bin/osascript -e 'on run argv' -e 'text returned of (display dialog "New commit message:" default answer (item 1 of argv))' -e 'end run' "$cur" 2>/dev/null) || exit 0
[ -z "$new" ] && exit 0
export FORK_MSG="$new"
out=$(GIT_SEQUENCE_EDITOR='sed -i "" "1s/^pick /reword /"' GIT_EDITOR='f(){ printf "%s\n" "$FORK_MSG" > "$1"; }; f' git rebase -i --autostash "$sha^" 2>&1) || {
  git rebase --abort >/dev/null 2>&1
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: reword failed" message (item 1 of argv) as critical' -e 'end run' "$out"
  exit 1
}
exit 0
