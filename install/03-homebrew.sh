#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "Homebrew"
[[ -x /opt/homebrew/bin/brew ]] \
    || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"   # a fresh Mac gets brew on PATH only in step 4
log "$(brew --version | head -1)"

section "minimum packages (homebrew/minimum_brewfile)"
if brew bundle check --file "$DOTFILES/homebrew/minimum_brewfile" >/dev/null 2>&1; then
    log "all installed"
else
    brew bundle --quiet --file "$DOTFILES/homebrew/minimum_brewfile"
fi

section "shell completions for brew commands"
brew completions link >/dev/null
log "linked"
