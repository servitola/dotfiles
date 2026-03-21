#!/bin/zsh
# where_is_my_space — macOS cleanup script
# Cleans caches, logs, crash reports, and temporary files
#
# Usage (local):  ~/projects/dotfiles/cleanup/cleanup_all.sh
# Usage (curl):   curl -fsSL .../cleanup/clean.sh | zsh

: "${CLEANUP_DIR:=$(dirname "$0")}"
source "$CLEANUP_DIR/helpers.sh"
source "$CLEANUP_DIR/try_clean.sh"

# --- Environment ---

: "${HOMEBREW_PREFIX:=/opt/homebrew}"
[ ! -d "$HOMEBREW_PREFIX" ] && HOMEBREW_PREFIX="/usr/local"

if command -v realrm &>/dev/null; then
    RM_CMD="realrm"
else
    RM_CMD="/bin/rm"
fi

# Gruvbox colors
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

print_section() {
    printf "\n${BLUE}${BOLD}━━━ %s ━━━${NC}\n" "$1"
}

print_task() {
    printf "\n${GREEN}${BOLD}⚡${NC} ${BOLD}%s${NC}\n" "$1"
}

# --- Main ---

sudo -v </dev/tty

_free_bytes_before=$(df -k / | awk 'NR==2 {print $4}')

print_section "System Maintenance"

print_task "Rebuilding zsh completion cache"
setopt nonomatch
rm -f ~/.zcompdump* 2>/dev/null
unsetopt nonomatch
chmod -R go-w "$HOMEBREW_PREFIX/share" 2>/dev/null || true

print_task "Flushing DNS cache"
dscacheutil -flushcache
sudo killall -HUP mDNSResponder 2>/dev/null </dev/null || true

print_task "Cleaning caches"
setopt rm_star_silent
source "$CLEANUP_DIR/cleanup_targets.sh"

print_task "Cleaning Homebrew cask installers"
CASKROOM="$HOMEBREW_PREFIX/Caskroom"
if [ -d "$CASKROOM" ]; then
    cask_installers_count=$(find "$CASKROOM" -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$cask_installers_count" -gt 0 ]; then
        spinner_start "Cask installers"
        cask_size_kb=$(find "$CASKROOM" -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
        find "$CASKROOM" -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" -delete 2>/dev/null
        spinner_stop "Cask installers: cleaned ($cask_installers_count files, $(format_size $cask_size_kb))"
    else
        printf "  ${DIM}* Cask installers: nothing to clean${NC}\n"
    fi
else
    printf "  ${DIM}* Cask installers: Homebrew Caskroom not found${NC}\n"
fi

print_task "Cleaning unused Docker images"
docker image prune -f

print_task "Cleaning Trash"
try_clean_pattern /Volumes d ".Trashes" "Volume Trashes"
try_clean_pattern /private/var/log/asl f "*.asl" "ASL Logs"
if [ -w ~/.Trash ]; then
    try_clean ~/.Trash "User Trash"
else
    trash_kb=$(du -sk ~/.Trash 2>/dev/null | cut -f1)
    if [ -n "$trash_kb" ] && [ "$trash_kb" -gt 0 ]; then
        spinner_start "User Trash"
        if "$RM_CMD" -rf ~/.Trash/* 2>/dev/null; then
            spinner_stop "User Trash: cleaned ($(format_size $trash_kb))"
        else
            spinner_stop_error "User Trash: ERROR - permission denied (protected by system)"
        fi
    else
        printf "  ${DIM}* User Trash: already empty${NC}\n"
    fi
fi

setopt no_rm_star_silent

_free_bytes_after=$(df -k / | awk 'NR==2 {print $4}')
_freed_kb=$(( _free_bytes_after - _free_bytes_before ))
_free_gb=$(( _free_bytes_after / 1048576 ))

printf "\n${YELLOW}${BOLD}✨ All cleanup completed! Freed $(format_size $_freed_kb) (${_free_gb} GB available)${NC}\n"
