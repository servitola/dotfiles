#!/bin/zsh
# Runs inside the VM after make.
#   checks.sh remake   a second make changes nothing
#   checks.sh links    no symlink under ~ points nowhere
#   checks.sh shell    an interactive zsh starts quietly and fast
setopt err_exit pipe_fail
path=(/opt/homebrew/bin $path)
typeset -F SECONDS

case $1 in
    remake)
        output=$(cd ~/projects/dotfiles && make 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g')
        print -r -- $output
        changed=$(print -r -- $output | grep '^      ✓ ' | grep -v 'everything in place' || true)
        [[ -z $changed ]] || { print "\nchanged on the second run:\n$changed"; exit 1 } ;;
    links)
        broken=$( {
            find ~ \( -path ~/Library -o -name .Trash -o -name .git -o -name node_modules -o -path ~/.cache \) -prune \
                -o -type l ! -exec test -e {} \; -print
            find ~/Library/LaunchAgents ~/Library/Application\ Support -maxdepth 3 -type l ! -exec test -e {} \; -print
        } 2>/dev/null )
        [[ -z $broken ]] || { print "symlinks to nothing:\n$broken"; exit 1 }
        print "no broken symlinks" ;;
    shell)
        # On a terminal, as a person opens it: without one zsh complains about job
        # control and gitstatus, which no real start does.
        start_shell() {
            TERM=xterm-256color script -q /dev/null zsh -ic exit </dev/null |
                sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\x1b\][^\x07]*\x07//g; s/\^D//g' | tr -d '\r\004\010' |
                grep -v '^[[:space:]]*$' || true
        }
        start_shell >/dev/null   # the first start after up rebuilds the caches up deleted
        started=$SECONDS
        output=$(start_shell)
        took=$(( SECONDS - started ))
        printf 'interactive zsh in %.2fs\n' $took
        [[ -z $output ]] || { print -r -- "it printed:"; print -r -- $output; exit 1 }
        (( took < 1 )) ;;
esac
