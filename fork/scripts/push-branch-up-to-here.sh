#!/usr/bin/env bash
sha="$1"

branch=$(git rev-parse --abbrev-ref HEAD)
remote=$(git config "branch.$branch.remote")
[ -z "$remote" ] && remote=origin
out=$(git push "$remote" "$sha:refs/heads/$branch" 2>&1)
status=$?
[ "$status" -ne 0 ] && /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: push failed" message (item 1 of argv) as critical' -e 'end run' "$out"
exit $status
