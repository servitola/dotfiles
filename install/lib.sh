#!/bin/zsh
# Sourced first by install.sh and by every step.

DOTFILES="$HOME/projects/dotfiles"
APP_SUPPORT="$HOME/Library/Application Support"
CONFIG="$HOME/.config"
CLAUDE_CODE="$DOTFILES/claude-code"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
CLAUDE_PROJECT="$HOME/.claude/projects/-Users-servitola-projects-dotfiles"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
source "$DOTFILES/constants/load.zsh"

_reset=$'\e[0m'; _dim=$'\e[2m'; _bold=$'\e[1m'
_red=$'\e[31m'; _green=$'\e[32m'; _yellow=$'\e[33m'; _blue=$'\e[34m'

section() { print -r -- "  ${_yellow}==>${_reset} $*"; }
log()     { print -r -- "      $*"; }
ok()      { print -r -- "      ${_green}✓${_reset} $*"; }
warn()    { print -r -- "      ${_yellow}!${_reset} $*"; }
err()     { print -r -- "      ${_red}✗${_reset} $*" >&2; }

# Everything printed is also written to a log file: colored on screen, plain in the file.
LOGFILE=""
start_logging() {
    mkdir -p "$STATE"
    LOGFILE="$STATE/install-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee >(sed -E 's/\x1b\[[0-9;]*m//g' >> "$LOGFILE")) 2>&1
    log "logging to $LOGFILE"
}

# run_step <file> <number> <count> — runs one step in its own zsh, with a heading and its time.
run_step() {
    local name=${${1:t:r}#[0-9][0-9]-} started=$SECONDS
    print -r -- ""
    print -r -- "${_blue}${_bold}━━ [$2/$3] $name${_reset}"
    if zsh "$1"; then
        print -r -- "  ${_green}✓ done${_reset} ${_dim}($(( SECONDS - started ))s)${_reset}"
    else
        print -r -- "  ${_red}${_bold}✗ FAILED: $name${_reset} — see $LOGFILE" >&2
        return 1
    fi
}

finish() {
    print -r -- ""
    print -r -- "${_green}${_bold}✓ Installation complete${_reset} ${_dim}(${SECONDS}s · $LOGFILE)${_reset}"
    zsh zsh/bin/random_ascii.sh
}

# link <source> <destination>: sudo because some destinations are system paths
# and older runs left root-owned links in $HOME.
# Every link is also listed in $STATE/links.tsv, for install/check.sh.
link() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname "$destination")" "$STATE"
    sudo rm -rf "$destination"
    sudo ln -sfh "$source" "$destination"
    log "${destination/#$HOME/~} -> ${${source#$DOTFILES/}/#$HOME/~}"
    print -r -- "$destination"$'\t'"$source" >> "$STATE/links.tsv"
}

# link_all <source> <destination> <source> <destination> ...
link_all() {
    local i
    for (( i = 1; i <= $#; i += 2 )); do
        link "${@[i]}" "${@[i+1]}"
    done
}
