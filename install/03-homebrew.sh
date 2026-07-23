#!/bin/zsh
# Step 03 — Homebrew: bootstrap brew, minimum packages, completions.
source "${0:a:h}/lib.sh"
set -euo pipefail

# External scripts run as subprocesses (not sourced) so their own error
# handling stays theirs and our set -e doesn't leak into them.
zsh "$DOTFILES/homebrew/install.sh"
zsh "$DOTFILES/homebrew/install_minimum_homebrew_packages.sh"

section "Linking Homebrew completions for external commands"
brew completions link
