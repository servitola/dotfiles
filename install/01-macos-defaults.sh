#!/bin/zsh
# Step 01 — macOS defaults (Finder, keyboard, Dock, dark mode, …).
source "${0:a:h}/lib.sh"
exec zsh "$DOTFILES/macos/set_defaults.sh"
