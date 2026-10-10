#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "Homebrew"
[[ -x /opt/homebrew/bin/brew ]] \
    || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"   # a fresh Mac gets brew on PATH only in step 4
log "$(brew --version | head -1)"

section "npm and uv config"
# Before brew bundle: its npm and uv entries read them, and without ~/.npmrc the
# npm globals land in /opt/homebrew, where they collide with formulae.
link_all \
    "$DOTFILES/npm/npmrc"             "$HOME/.npmrc" \
    "$DOTFILES/uv/uv.toml"            "$CONFIG/uv/uv.toml" \
    "$DOTFILES/uv/.python-version"    "$CONFIG/uv/.python-version"

section "packages (homebrew/brewfile)"
# Everything, not a subset: a hand-kept minimum list kept drifting from what
# make and up call. One entry that cannot install (a moved cask download, a mas
# app before the App Store sign-in) must not leave the Mac unconfigured, so the
# failures are reported and the install goes on; check.sh judges the result.
# Upgrades are up's job, so make only fills in what is missing.
# brew bundle cannot see App Store apps here: mas 2 lists them through
# Spotlight, which is off, so it calls every one missing. An app counts as
# installed when its bundle carries an App Store receipt (as in mas-dump.sh).
mkdir -p "$STATE"
brewfile=$STATE/brewfile
grep -v '^mas ' "$DOTFILES/homebrew/brewfile" > "$brewfile"
missing_mas=()
for line in ${(f)"$(grep '^mas ' "$DOTFILES/homebrew/brewfile")"}; do
    name=${${line#mas \"}%%\"*}
    [[ -e "/Applications/$name.app/Contents/_MASReceipt/receipt" ]] || missing_mas+=$line
done
# mas waits forever, not fails, for a Store nobody signed in to (measured:
# 2 h in the VM test), and it can no longer tell whether anyone has. So a
# person confirms the sign-in; without one the missing apps are left out.
if (( $#missing_mas )); then
    reply=s
    if [[ -t 0 ]]; then
        open -a "App Store"
        read -r "reply?      ${#missing_mas} App Store apps to install: sign in to the App Store and press Enter, or type s to skip them: "
    fi
    if [[ $reply == s ]]; then
        warn "${#missing_mas} App Store apps skipped: sign in, then run make again"
    else
        print -l -- $missing_mas >> "$brewfile"
    fi
fi
# brew bundle installs uv tools with UV_PYTHON forced to the newest Homebrew
# Python (bundle/extensions/uv.rb), over the 3.12 pin in uv/.python-version:
# mlx-whisper then failed on 3.15. Installed here first, they keep the pin and
# bundle finds them in place.
[[ -x /opt/homebrew/bin/uv ]] || brew install --quiet uv
for tool in ${(f)"$(sed -n 's/^uv "\([^"]*\)".*/\1/p' "$brewfile")"}; do
    uv tool install --quiet "$tool" || warn "uv tool $tool did not install"
done
if brew bundle check --no-upgrade --file "$brewfile" >/dev/null 2>&1; then
    log "all installed"
else
    brew bundle --quiet --no-upgrade --file "$brewfile" || warn "brew bundle: the entries above failed"
fi
# cargo-about builds its binary only with --features cli since 0.9, and a
# brewfile cargo line cannot pass features: bundle "installs" nothing, silently.
cargo install --list | grep -q '^cargo-about ' ||
    cargo install --quiet --locked cargo-about --features cli || warn "cargo-about did not install"

section "quarantine flags off the casks"
# Otherwise step 18's `open Hammerspoon.app` waits forever on the
# "downloaded from the Internet" dialog that nobody sees during an install.
source "$DOTFILES/macos_update/functions.sh"
brew_unquarantine >/dev/null
log "cleared"

section "shell completions for brew commands"
brew completions link >/dev/null
log "linked"
