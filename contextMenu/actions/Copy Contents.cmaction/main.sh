#!/bin/zsh
if [ -f "$1" ]; then
    cat "$@" | pbcopy
fi
