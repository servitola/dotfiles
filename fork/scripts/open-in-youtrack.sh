#!/usr/bin/env bash
sha="$1"

commit_message=$(git show -s --format=%B "$sha")

if [[ $commit_message =~ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
    open "https://yt.workproject.com/issue/$ticket"
else
    echo "No ticket number found in commit message: $commit_message"
    exit 1
fi
