#!/usr/bin/env bash

if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  /usr/bin/osascript -e 'display notification "Nothing to move — working tree is clean" with title "Fork"'
  exit 0
fi
name=$(/usr/bin/osascript -e 'text returned of (display dialog "New branch name (carries your uncommitted changes):" default answer "")' 2>/dev/null) || exit 0
branch=$(printf '%s' "$name" | sed -E 's#[^A-Za-z0-9._/-]+#-#g; s#-+#-#g; s#^[-/]+|[-/]+$##g')
[ -z "$branch" ] && exit 0
out=$(git switch -c "$branch" 2>&1) || {
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: cannot create branch" message (item 1 of argv) as critical' -e 'end run' "$out"
  exit 1
}
exit 0
