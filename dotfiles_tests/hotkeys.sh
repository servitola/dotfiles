#!/bin/zsh
# Runs inside the VM, against the Hammerspoon that make started.
#   hotkeys.sh live   every chord of the layout tables is a bound hotkey
#   hotkeys.sh apps   every app chord brings its app to the front
setopt err_exit
path=(/opt/homebrew/bin $path)
here=${0:a:h}

case $1 in
    live)
        hs -c "dofile('$here/hotkeys_live.lua')" </dev/null ;;
    apps)
        rm -f /tmp/hotkeys_apps.txt
        hs -c "dofile('$here/hotkeys_apps.lua')" </dev/null
        until grep -qx done /tmp/hotkeys_apps.txt 2>/dev/null; do sleep 2; done
        cat /tmp/hotkeys_apps.txt
        ! grep -q '^FAIL' /tmp/hotkeys_apps.txt ;;
esac
