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

RM_CMD="/bin/rm"

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

if [ "$AGGRESSIVE" = "true" ]; then
    print_section "Aggressive Cleanup"

    print_task "Cleaning Go module cache"
    if command -v go &>/dev/null; then
        spinner_start "Go module cache"
        go clean -modcache 2>/dev/null
        spinner_stop "Go module cache: cleaned"
    else
        printf "  ${DIM}* Go module cache: go not found${NC}\n"
    fi

    print_task "Cleaning all NuGet caches"
    if command -v dotnet &>/dev/null; then
        spinner_start "NuGet all caches"
        dotnet nuget locals all --clear 2>/dev/null
        spinner_stop "NuGet all caches: cleaned"
    else
        printf "  ${DIM}* NuGet caches: dotnet not found${NC}\n"
    fi

    print_task "Cleaning npm cache"
    if command -v npm &>/dev/null; then
        spinner_start "npm cache"
        npm cache clean --force 2>/dev/null
        spinner_stop "npm cache: cleaned"
    else
        printf "  ${DIM}* npm cache: npm not found${NC}\n"
    fi

    print_task "Cleaning Docker (all unused images + build cache)"
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        spinner_start "Docker system prune"
        docker system prune -a -f 2>/dev/null
        docker builder prune -a -f 2>/dev/null
        spinner_stop "Docker system + build cache: cleaned"
    else
        printf "  ${DIM}* Docker: not running${NC}\n"
    fi

    print_task "Aggressive git gc + prune (all repositories)"
    _git_repo_count=0
    while IFS= read -r -d '' git_dir; do
        repo_path="${git_dir%/.git}"
        cd "$repo_path" 2>/dev/null || continue
        git rev-parse --git-dir &>/dev/null || continue
        _git_repo_count=$(( _git_repo_count + 1 ))
        printf "  ${DIM}* Pruning: ${repo_path/#$HOME/~}${NC}\r"
        git reflog expire --expire=now --expire-unreachable=now --all 2>/dev/null
        git gc --aggressive --prune=now 2>/dev/null
        git remote prune origin 2>/dev/null
        git fetch --prune 2>/dev/null
        git repack -a -d --depth=250 --window=250 2>/dev/null
        git prune --expire=now 2>/dev/null
    done < <(find "$HOME" -type d -name ".git" -not -path "*/node_modules/*" -not -path "*/.Trash/*" -not -path "*/Library/*" -print0 2>/dev/null)
    printf "\r\033[K  ${_S_GREEN}${_S_BOLD}* Git aggressive gc: pruned ${_git_repo_count} repositories${_S_NC}\n"
fi

_free_bytes_after=$(df -k / | awk 'NR==2 {print $4}')
_freed_kb=$(( _free_bytes_after - _free_bytes_before ))
_free_gb=$(( _free_bytes_after / 1048576 ))

printf "\n${YELLOW}${BOLD}✨ All cleanup completed! Freed $(format_size $_freed_kb) (${_free_gb} GB available)${NC}\n"
