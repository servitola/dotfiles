#!/bin/zsh
cmd1="$HOME/Applications/Rider.app/Contents/MacOS/rider"
cmd2='/Applications/Rider.app/Contents/MacOS/rider'
if [ -x "$cmd1" ]; then
    cmd="$cmd1"
elif [ -x "$cmd2" ]; then
    cmd="$cmd2"
fi
if [ -n "$cmd" ]; then
    "$cmd" "$@"
else
    open -a Rider "$@"
fi
