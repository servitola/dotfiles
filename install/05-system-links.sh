#!/bin/zsh
# Step 05 — system links that need root: /etc/hosts, dotnet.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "hosts file (may need a manual redo later)"
link "$DOTFILES/macos/hosts" /etc/hosts

section "dotnet symlink on /opt/homebrew/bin"
# dotnet lives in keg-less ~/.dotnet; link it onto /opt/homebrew/bin (always
# on PATH) so stale-PATH shells and workbot2 (hardcoded brew path) find it.
ln -sfv "$HOME/.dotnet/dotnet" /opt/homebrew/bin/dotnet
