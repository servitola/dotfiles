#!/bin/zsh
# Step 12 — package-manager configs + global installs: npm, uv, aichat.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "config symlinks (npm, uv, aichat)"
link_all \
    "$DOTFILES/npm/npmrc"             "$HOME/.npmrc" \
    "$DOTFILES/uv/uv.toml"            "$CONFIG/uv/uv.toml" \
    "$DOTFILES/aichat/config.yaml"    "$APP_SUPPORT/aichat/config.yaml" \
    "$DOTFILES/aichat/dark.tmTheme"   "$APP_SUPPORT/aichat/dark.tmTheme"

section "installing global npm packages"
zsh "$DOTFILES/npm/install-globals.sh"       # subprocess: keeps its errors its own
