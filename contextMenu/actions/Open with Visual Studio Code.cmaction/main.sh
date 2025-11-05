#!/bin/bash
cmd1='/usr/local/bin/code'
cmd2='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
if [ -f "$cmd1" ]; then
    cmd="$cmd1"
elif [ -f "$cmd2" ]; then
    cmd="$cmd2"
fi
if [ -n "$cmd" ]; then
    "$cmd" "$@"
fi
