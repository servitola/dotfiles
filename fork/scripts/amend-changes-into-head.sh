#!/usr/bin/env bash

if git diff --quiet && git diff --cached --quiet; then
  /usr/bin/osascript -e 'display notification "Nothing to amend" with title "Fork"'
  exit 0
fi
git add -A
out=$(git commit --amend --no-edit 2>&1) || {
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: amend failed" message (item 1 of argv) as critical' -e 'end run' "$out"
  exit 1
}
exit 0
