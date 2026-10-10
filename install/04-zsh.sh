#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "zsh as the login shell"
[[ $SHELL == $(command -v zsh) ]] || chsh -s "$(command -v zsh)"

section "zsh config"
link_all \
    "$DOTFILES/zsh/zshrc.sh"    "$HOME/.zshrc" \
    "$DOTFILES/zsh/zshenv.sh"   "$HOME/.zshenv" \
    "$DOTFILES/zsh/zprofile.sh" "$HOME/.zprofile"

section "secrets file (\$FILE_SECRETS)"
# Every shell sources it. Where its keys come from on a new Mac is not settled
# yet, so a fresh one gets an empty file to fill in by hand.
if [[ -e $FILE_SECRETS ]]; then
    log "present"
else
    mkdir -p "${FILE_SECRETS:h}"
    install -m 600 /dev/null "$FILE_SECRETS"
    warn "created an empty ${FILE_SECRETS/#$HOME/~}: API keys go there"
fi

section "oh-my-zsh"
if [[ -d $HOME/.oh-my-zsh ]]; then
    log "already installed"
else
    # --unattended: the stock installer would replace ~/.zshrc and start a new shell.
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

section "powerlevel10k"
theme=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
if [[ -d $theme ]]; then
    git -C "$theme" pull --quiet
    log "up to date"
else
    git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme"
    log "installed"
fi
