#!/bin/zsh
cmd1='/opt/homebrew/bin/fork'
cmd2='/usr/local/bin/fork'
cmd3='/Applications/Fork.app/Contents/Resources/fork_cli'
if [ -x "$cmd1" ]; then
    cmd="$cmd1"
elif [ -x "$cmd2" ]; then
    cmd="$cmd2"
elif [ -x "$cmd3" ]; then
    cmd="$cmd3"
fi
if [ -n "$cmd" ]; then
    for target in "$@"; do
        if [ -d "$target" ]; then
            dir="$target"
        else
            dir="$(dirname "$target")"
        fi
        "$cmd" -C "$dir"
    done
else
    open -a Fork "$@"
fi
