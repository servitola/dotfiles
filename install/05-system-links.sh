#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "/etc/hosts"
link "$DOTFILES/macos/hosts" /etc/hosts

section "dotnet symlink on /opt/homebrew/bin"
# dotnet lives in ~/.dotnet; tools with a hardcoded Homebrew path (workbot2) look here.
ln -sfv "$HOME/.dotnet/dotnet" /opt/homebrew/bin/dotnet
