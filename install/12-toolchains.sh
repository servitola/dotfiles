#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "config symlinks (aichat)"
link_all \
    "$DOTFILES/aichat/config.yaml"    "$APP_SUPPORT/aichat/config.yaml" \
    "$DOTFILES/aichat/dark.tmTheme"   "$APP_SUPPORT/aichat/dark.tmTheme"

section "global npm packages (npm/global-packages.txt)"
zsh "$DOTFILES/npm/install-globals.sh"
