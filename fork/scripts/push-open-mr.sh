#!/usr/bin/env bash

branch=$(git rev-parse --abbrev-ref HEAD)
case "$branch" in
  Development|develop|main|master|HEAD)
    /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: not a feature branch" message (item 1 of argv) as critical' -e 'end run' "You are on $branch — switch to a feature branch first."
    exit 1;;
esac
main=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
[ -z "$main" ] && main=Development
out=$(git push -u origin "$branch" 2>&1) || {
  /usr/bin/osascript -e 'on run argv' -e 'display alert "Fork: push failed" message (item 1 of argv) as critical' -e 'end run' "$out"
  exit 1
}
url=$(git remote get-url origin | sed -E 's#\.git$##; s#^git@([^:]+):#https://\1/#')
enc() { /usr/bin/python3 -c 'import sys,urllib.parse as u; print(u.quote(sys.argv[1], safe=""))' "$1"; }
ticket=$(printf '%s' "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1)
q="merge_request%5Bsource_branch%5D=$(enc "$branch")&merge_request%5Btarget_branch%5D=$(enc "$main")"
[ -n "$ticket" ] && q="$q&merge_request%5Btitle%5D=$(enc "$ticket")"
open "$url/-/merge_requests/new?$q"
exit 0
