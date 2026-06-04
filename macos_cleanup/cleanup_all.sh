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

print_task "Atuin maintenance"
ATUIN_DIR="$HOME/.local/share/atuin"
if [ -d "$ATUIN_DIR" ] && command -v sqlite3 &>/dev/null; then
    spinner_start "Atuin backups + VACUUM"
    atuin_before_kb=$(du -sk "$ATUIN_DIR" 2>/dev/null | cut -f1)
    "$RM_CMD" -rf "$ATUIN_DIR/backups/"* 2>/dev/null
    for db in history.db records.db kv.db meta.db scripts.db; do
        [ -f "$ATUIN_DIR/$db" ] && sqlite3 "$ATUIN_DIR/$db" 'VACUUM;' 2>/dev/null
    done
    atuin_after_kb=$(du -sk "$ATUIN_DIR" 2>/dev/null | cut -f1)
    atuin_freed_kb=$(( atuin_before_kb - atuin_after_kb ))
    spinner_stop "Atuin: freed $(format_size $atuin_freed_kb)"
else
    printf "  ${DIM}* Atuin: not installed or sqlite3 missing${NC}\n"
fi

print_task "Mole cache (older than 14 days)"
MOLE_DIR="$HOME/.cache/mole"
if [ -d "$MOLE_DIR" ]; then
    spinner_start "Mole stale scan cache"
    mole_before_kb=$(du -sk "$MOLE_DIR" 2>/dev/null | cut -f1)
    find "$MOLE_DIR" -type f -name "*.cache" -mtime +14 -delete 2>/dev/null
    mole_after_kb=$(du -sk "$MOLE_DIR" 2>/dev/null | cut -f1)
    mole_freed_kb=$(( mole_before_kb - mole_after_kb ))
    if [ "$mole_freed_kb" -gt 0 ]; then
        spinner_stop "Mole: freed $(format_size $mole_freed_kb)"
    else
        spinner_stop "Mole: nothing to clean"
    fi
else
    printf "  ${DIM}* Mole: no cache directory${NC}\n"
fi

print_task "Orphan AAX plugins (no Pro Tools installed)"
AVID_DIR="/Library/Application Support/Avid"
if [ -d "$AVID_DIR" ] && [ ! -d "/Applications/Pro Tools.app" ]; then
    spinner_start "Orphan AAX cleanup"
    avid_before_kb=$(du -sk "$AVID_DIR" 2>/dev/null | cut -f1)
    sudo "$RM_CMD" -rf "$AVID_DIR" 2>/dev/null
    if [ ! -d "$AVID_DIR" ]; then
        spinner_stop "Avid AAX: freed $(format_size $avid_before_kb) (no Pro Tools, plugins were orphan)"
    else
        spinner_stop_error "Avid AAX: failed (need sudo)"
    fi
elif [ -d "/Applications/Pro Tools.app" ]; then
    printf "  ${DIM}* Avid AAX: Pro Tools installed, keeping plugins${NC}\n"
else
    printf "  ${DIM}* Avid AAX: nothing to clean${NC}\n"
fi

print_task "Steam htmlcache (CEF browser cache)"
STEAM_HTMLCACHE="$HOME/Library/Application Support/Steam/config/htmlcache"
if [ -d "$STEAM_HTMLCACHE" ]; then
    if pgrep -x "steam_osx" > /dev/null || pgrep -x "Steam" > /dev/null; then
        printf "  ${DIM}* Steam htmlcache: Steam is running, skipping${NC}\n"
    else
        spinner_start "Steam embedded browser cache"
        steam_before_kb=$(du -sk "$STEAM_HTMLCACHE" 2>/dev/null | cut -f1)
        "$RM_CMD" -rf "$STEAM_HTMLCACHE"/* 2>/dev/null
        steam_after_kb=$(du -sk "$STEAM_HTMLCACHE" 2>/dev/null | cut -f1)
        steam_freed_kb=$(( steam_before_kb - steam_after_kb ))
        if [ "$steam_freed_kb" -gt 0 ]; then
            spinner_stop "Steam htmlcache: freed $(format_size $steam_freed_kb)"
        else
            spinner_stop "Steam htmlcache: nothing to clean"
        fi
    fi
else
    printf "  ${DIM}* Steam htmlcache: not installed${NC}\n"
fi

print_task "Google DriveFS logs"
DRIVEFS_LOGS="$HOME/Library/Application Support/Google/DriveFS/Logs"
if [ -d "$DRIVEFS_LOGS" ]; then
    spinner_start "DriveFS logs"
    drivefs_before_kb=$(du -sk "$DRIVEFS_LOGS" 2>/dev/null | cut -f1)
    "$RM_CMD" -rf "$DRIVEFS_LOGS"/* 2>/dev/null
    drivefs_after_kb=$(du -sk "$DRIVEFS_LOGS" 2>/dev/null | cut -f1)
    drivefs_freed_kb=$(( drivefs_before_kb - drivefs_after_kb ))
    if [ "$drivefs_freed_kb" -gt 0 ]; then
        spinner_stop "DriveFS Logs: freed $(format_size $drivefs_freed_kb)"
    else
        spinner_stop "DriveFS Logs: nothing to clean"
    fi
else
    printf "  ${DIM}* DriveFS Logs: not installed${NC}\n"
fi

print_task "Palo Alto GlobalProtect logs (older than 7 days)"
GP_LOG_DIR="/Library/Logs/PaloAltoNetworks/GlobalProtect"
if [ -d "$GP_LOG_DIR" ]; then
    spinner_start "GlobalProtect log rotation"
    gp_before_kb=$(du -sk "$GP_LOG_DIR" 2>/dev/null | cut -f1)
    # Rotated logs (PanGPS.1.log, PanGpHip.2.log, etc.) — always safe to drop
    find "$GP_LOG_DIR" -maxdepth 1 -type f -name "*.[0-9].log" -delete 2>/dev/null
    # Older log files (no rotation suffix) only if untouched 7+ days
    find "$GP_LOG_DIR" -maxdepth 1 -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    gp_after_kb=$(du -sk "$GP_LOG_DIR" 2>/dev/null | cut -f1)
    gp_freed_kb=$(( gp_before_kb - gp_after_kb ))
    if [ "$gp_freed_kb" -gt 0 ]; then
        spinner_stop "GlobalProtect: freed $(format_size $gp_freed_kb)"
    else
        spinner_stop "GlobalProtect: nothing to clean"
    fi
else
    printf "  ${DIM}* GlobalProtect: log directory not found${NC}\n"
fi

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
