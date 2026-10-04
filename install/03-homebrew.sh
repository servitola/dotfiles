#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

zsh "$DOTFILES/homebrew/install.sh"
zsh "$DOTFILES/homebrew/install_minimum_homebrew_packages.sh"

section "Linking Homebrew completions for external commands"
brew completions link
