#!/bin/zsh
# Step 04 — zsh as the default shell + oh-my-zsh + powerlevel10k.
source "${0:a:h}/lib.sh"
exec zsh "$DOTFILES/zsh/setup_zsh.sh"
