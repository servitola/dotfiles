#!/usr/bin/env bash

branches=$(git branch --merged Development | grep -v '\*\|Development')
if [ -n "$branches" ]; then
    echo "$branches" | xargs git branch -d
else
    echo "No merged branches to clean"
fi
