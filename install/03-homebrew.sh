#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "Homebrew"
[[ -x /opt/homebrew/bin/brew ]] \
    || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"   # a fresh Mac gets brew on PATH only in step 4
log "$(brew --version | head -1)"

section "packages (homebrew/brewfile)"
# Everything, not a subset: a hand-kept minimum list kept drifting from what
# make and up call. One entry that cannot install (a moved cask download, a mas
# app before the App Store sign-in) must not leave the Mac unconfigured, so the
# failures are reported and the install goes on; check.sh judges the result.
# Upgrades are up's job, so make only fills in what is missing.
if brew bundle check --no-upgrade --file "$DOTFILES/homebrew/brewfile" >/dev/null 2>&1; then
    log "all installed"
else
    # mas installs only for a signed-in App Store, and mas 2 can no longer tell
    # whether it is, so a person confirms before the long unattended part.
    if [[ -t 0 ]] && grep -q '^mas ' "$DOTFILES/homebrew/brewfile"; then
        open -a "App Store"
        read -r "?      sign in to the App Store, then press Enter "
    fi
    brew bundle --no-upgrade --file "$DOTFILES/homebrew/brewfile" || warn "brew bundle: the entries above failed"
fi

section "quarantine flags off the casks"
# Otherwise step 18's `open Hammerspoon.app` waits forever on the
# "downloaded from the Internet" dialog that nobody sees during an install.
source "$DOTFILES/macos_update/functions.sh"
brew_unquarantine >/dev/null
log "cleared"

section "shell completions for brew commands"
brew completions link >/dev/null
log "linked"
