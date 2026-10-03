#!/bin/zsh
#
# Shared paths, logging, and helpers for the installer. Every step sources
# this first, so steps stay tiny — all the formatting lives here, no per-step
# echo tricks.

# --- Paths (full words, no $(D)/$(H)/$(A) shorthands) --------------------
DOTFILES="$HOME/projects/dotfiles"
APP_SUPPORT="$HOME/Library/Application Support"
CONFIG="$HOME/.config"
CLAUDE_CODE="$DOTFILES/claude-code"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
CLAUDE_PROJECT="$HOME/.claude/projects/-Users-servitola-projects-dotfiles"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"   # install logs + rendered configs

# --- Colors -------------------------------------------------------------
_reset=$'\e[0m'; _dim=$'\e[2m'; _bold=$'\e[1m'
_red=$'\e[31m'; _green=$'\e[32m'; _yellow=$'\e[33m'; _blue=$'\e[34m'

# --- Logging (a step just calls these) ----------------------------------
section() { print -r -- "  ${_yellow}==>${_reset} $*"; }   # sub-heading in a step
log()     { print -r -- "      $*"; }                       # plain detail line
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

# --- Symlink helpers ----------------------------------------------------
# link <source> <destination> — replace <destination> with a symlink.
# sudo is kept from the old Makefile: some targets are system paths, and
# existing $HOME symlinks may be root-owned from prior runs.
link() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname "$destination")"
    sudo rm -rf "$destination"
    sudo ln -sfvh "$source" "$destination"
}

# link_all <src1> <dst1> <src2> <dst2> ... — link a flat list of pairs.
link_all() {
    local i
    for (( i = 1; i <= $#; i += 2 )); do
        link "${@[i]}" "${@[i+1]}"
    done
}
