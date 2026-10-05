#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

changed=0
set_default() {  # <domain> <key> <type> <value>: writes only a value that differs
    local current=$(defaults read "$1" "$2" 2>/dev/null || true)
    [[ $3 == -bool ]] && current=${${current/1/true}/0/false}
    [[ $current == "$4" ]] && return
    defaults write "$1" "$2" "$3" "$4"
    changed=1
}

section "Dock: on the right, only Apps in it"
set_default com.apple.dock orientation -string right
set_default com.apple.dock showhidden -bool true               # dim the icons of hidden apps
set_default com.apple.dock minimize-to-application -bool true
set_default com.apple.dock show-recents -bool false
set_default com.apple.dock show-process-indicators -bool true
set_default com.apple.ActivityMonitor IconType -int 5          # CPU graph on its Dock icon

if [[ $(dockutil --list | cut -f1) != Apps ]]; then
    dockutil --no-restart --remove all
    dockutil --no-restart --add /System/Applications/Apps.app
    changed=1
fi

if (( changed )); then
    killall Dock
    log "updated"
else
    log "already so"
fi
