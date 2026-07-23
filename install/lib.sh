#!/bin/zsh
#
# Shared paths, logging, and helpers for the installer. Every step sources
# this first, so steps stay tiny — all the formatting lives here, no per-step
# echo tricks.

# --- Paths (full words, no $(D)/$(H)/$(A) shorthands) --------------------
DOTFILES="$HOME/projects/dotfiles"
PRIVATE="$HOME/projects/dotfiles_private"
APP_SUPPORT="$HOME/Library/Application Support"
CONFIG="$HOME/.config"
CLAUDE_CODE="$DOTFILES/claude-code"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
CLAUDE_PROJECT="$HOME/.claude/projects/-Users-servitola-projects-dotfiles"

# --- Colors -------------------------------------------------------------
_reset=$'\e[0m'; _dim=$'\e[2m'; _bold=$'\e[1m'
_red=$'\e[31m'; _green=$'\e[32m'; _yellow=$'\e[33m'; _blue=$'\e[34m'

# --- Logging (a step just calls these) ----------------------------------
section() { print -r -- "  ${_yellow}==>${_reset} $*"; }   # sub-heading in a step
log()     { print -r -- "      $*"; }                       # plain detail line
ok()      { print -r -- "      ${_green}✓${_reset} $*"; }
warn()    { print -r -- "      ${_yellow}!${_reset} $*"; }
err()     { print -r -- "      ${_red}✗${_reset} $*" >&2; }

# Step framing, used by install.sh around each step.
step_begin() { print -r -- ""; print -r -- "${_blue}${_bold}━━ [$1/$2] $3${_reset}"; }
step_ok()    { print -r -- "  ${_green}✓ done${_reset} ${_dim}(${1}s)${_reset}"; }
step_fail()  { print -r -- "  ${_red}${_bold}✗ FAILED: $1${_reset}" >&2; }

# Tee everything to a timestamped logfile: console keeps color, file is plain.
LOGFILE=""
log_init() {
    local dir="$HOME/.local/state/dotfiles"
    mkdir -p "$dir"
    LOGFILE="$dir/install-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee >(sed -E 's/\x1b\[[0-9;]*m//g' >> "$LOGFILE")) 2>&1
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

# copy_dir <source> <destination> — replace a dir with a fresh copy.
copy_dir() {
    local source="$1" destination="$2"
    sudo rm -rf "$destination"
    sudo cp -r "$source" "$destination"
}
