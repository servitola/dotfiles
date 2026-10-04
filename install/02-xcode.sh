#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "developer tools"
if ! xcode-select --print-path >/dev/null 2>&1; then
    xcode-select --install
    until xcode-select --print-path >/dev/null 2>&1; do sleep 5; done
fi
if [[ -d /Applications/Xcode.app ]]; then
    [[ $(xcode-select --print-path) == /Applications/Xcode.app/* ]] \
        || sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    xcodebuild -license check >/dev/null 2>&1 || sudo xcodebuild -license accept
fi
log "$(xcode-select --print-path)"

section "Xcode key bindings"
link "$DOTFILES/xcode/KeyBindings" "$HOME/Library/Developer/Xcode/UserData/KeyBindings"
