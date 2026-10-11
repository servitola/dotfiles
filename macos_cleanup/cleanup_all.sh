#!/bin/zsh
# where_is_my_space — macOS cleanup script
# Cleans caches, logs, crash reports, and temporary files
#
# Usage (local):  ~/projects/dotfiles/cleanup/cleanup_all.sh
# Usage (curl):   curl -fsSL .../cleanup/clean.sh | zsh

# Safety options: referencing an unset variable is an error (no_unset), so a
# typo'd variable can never expand to "" inside an rm path; pipelines report
# failures (pipe_fail). err_exit is deliberately NOT set — cleanup is
# conservative by design: missing/empty/running-app targets skip silently.
# Run as a child process (`zsh cleanup_all.sh`), don't source interactively.
setopt no_unset pipe_fail

: "${CLEANUP_DIR:=$(dirname "$0")}"
source "$CLEANUP_DIR/helpers.sh"
source "$CLEANUP_DIR/try_clean.sh"
source "$CLEANUP_DIR/relock_autostart.sh"
source "$CLEANUP_DIR/broken_links.sh"

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

print_task "Keeping uv's code signature stable for TCC"
# uv ships ad-hoc signed (no Team ID); TCC binds Full Disk Access to that
# ad-hoc identity, so every `brew upgrade uv` silently revokes the FDA grant
# the com.servitola.serho launchd chain depends on for /Volumes/* and
# ~/Documents etc. Re-signing with our own Developer ID gives it a team-anchored
# designated requirement, which TCC keeps matching across upgrades — same
# trick as the Transmission.app re-sign in ~/projects/forks/jobs/transmission/sync.sh.
UV_SIGN_ID="Developer ID Application: Developer Name (TEAMID1234)"
UV_BIN=$(readlink -f "$(command -v uv)" 2>/dev/null || true)
if [ -n "$UV_BIN" ] && [ -f "$UV_BIN" ]; then
    if ! codesign -dv "$UV_BIN" 2>&1 | grep -q "TeamIdentifier=TEAMID1234"; then
        codesign --force --sign "$UV_SIGN_ID" "$UV_BIN" 2>/dev/null \
            && printf "  ${DIM}* uv re-signed with stable Developer ID (was ad-hoc after upgrade)${NC}\n" \
            || printf "  ${DIM}* uv re-sign failed — Full Disk Access may need re-granting${NC}\n"
    fi
fi

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

print_task "uv cache (dangling entries + unused environments)"
# --force skips uv's in-use check. Without it the prune aborts whenever any uv
# process holds the cache — and the launchd shims (voiceink, piper, serho bot)
# hold it permanently here, so a guarded prune never ran once. It does remove
# the script environments those services run from, hence the restart below.
if command -v uv &>/dev/null; then
    spinner_start "uv cache prune"
    uv_cache_dir=$(uv cache dir 2>/dev/null)
    uv_before_kb=$(du -sk "$uv_cache_dir" 2>/dev/null | cut -f1)
    if uv cache prune --force &>/dev/null; then
        uv_after_kb=$(du -sk "$uv_cache_dir" 2>/dev/null | cut -f1)
        spinner_stop "uv cache: freed $(format_size $(( uv_before_kb - uv_after_kb )))"
        restart_services_with_deleted_uv_env "$uv_cache_dir"
    else
        spinner_stop_error "uv cache: prune failed"
    fi
else
    printf "  ${DIM}* uv cache: uv not found${NC}\n"
fi

print_task "Cleaning Docker dangling images + build cache"
# Safe on a live daemon: `image prune -f` drops only dangling images and
# `builder prune -af` clears build cache (reused by future builds only).
# Neither touches running containers, in-use images, or named volumes
# (your data) — verified against a fleet of 15 running containers.
# OrbStack TRIMs its data.img.raw live afterwards, so space is reclaimed
# on the host without stopping anything. Guarded so a stopped daemon skips.
if command -v docker &>/dev/null && docker info &>/dev/null; then
    spinner_start "Docker image + build cache prune"
    docker image prune -f &>/dev/null
    _docker_reclaimed=$(docker builder prune -a -f 2>/dev/null | awk '/^Total:/ {print $2}')
    spinner_stop "Docker: pruned dangling images + build cache${_docker_reclaimed:+ (build cache: $_docker_reclaimed)}"
else
    printf "  ${DIM}* Docker: daemon not running, skipping${NC}\n"
fi

print_task "LiteLLM spend logs (reclaim if bloated)"
# maximum_spend_logs_retention_period in litellm/config.yaml deletes old rows
# daily, but a plain DELETE leaves the table file at its high-water mark, so
# litellm_postgres_data never shrinks on its own. Only VACUUM FULL returns the
# space, and it takes an ACCESS EXCLUSIVE lock (~3 min for 8 GB) during which
# litellm cannot write spend logs — hence threshold + weekly rate limit rather
# than running it on every `up`. 7d of traffic is ~8.4 GB, so 11 GiB means
# genuine bloat, not normal growth.
LITELLM_SL_MAX=11811160064
LITELLM_SL_STAMP="$HOME/.cache/litellm-spendlogs-vacuum"
if command -v docker &>/dev/null && docker info &>/dev/null \
   && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx litellm-db; then
    _sl_size=$(print -r -- "select pg_total_relation_size(oid) from pg_class where relname = 'LiteLLM_SpendLogs';" \
        | docker exec -i litellm-db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA' 2>/dev/null \
        | tr -cd '0-9')
    if [ -z "$_sl_size" ]; then
        printf "  ${DIM}* LiteLLM spend logs: could not read table size, skipping${NC}\n"
    elif [ "$_sl_size" -le "$LITELLM_SL_MAX" ]; then
        printf "  ${DIM}* LiteLLM spend logs: $(format_size $(( _sl_size / 1024 ))), under threshold${NC}\n"
    elif [ -n "$(find "$LITELLM_SL_STAMP" -mtime -7 2>/dev/null)" ]; then
        printf "  ${DIM}* LiteLLM spend logs: bloated but vacuumed less than 7 days ago${NC}\n"
    else
        spinner_start "LiteLLM_SpendLogs VACUUM FULL"
        if print -r -- 'VACUUM (FULL, ANALYZE) "LiteLLM_SpendLogs";' \
            | docker exec -i litellm-db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1' &>/dev/null; then
            _sl_after=$(print -r -- "select pg_total_relation_size(oid) from pg_class where relname = 'LiteLLM_SpendLogs';" \
                | docker exec -i litellm-db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA' 2>/dev/null \
                | tr -cd '0-9')
            touch "$LITELLM_SL_STAMP"
            spinner_stop "LiteLLM spend logs: freed $(format_size $(( (_sl_size - ${_sl_after:-$_sl_size}) / 1024 )))"
        else
            spinner_stop_error "LiteLLM spend logs: VACUUM FULL failed"
        fi
    fi
else
    printf "  ${DIM}* LiteLLM spend logs: litellm-db not running, skipping${NC}\n"
fi

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

print_task "mma HTTP cache (APFS-compress new entries)"
MMA_CACHE="$DIR_EXTERNAL/projects/mma/data/cache"
MMA_AFSC_STAMP="$MMA_CACHE/.afsc-stamp"
if ! command -v afsctool &>/dev/null || [ ! -d "$MMA_CACHE" ]; then
    printf "  ${DIM}* mma cache: afsctool or cache dir missing, skipping${NC}\n"
elif [ -n "$(find "$MMA_AFSC_STAMP" -mtime -14 2>/dev/null)" ]; then
    printf "  ${DIM}* mma cache: compressed less than 14 days ago${NC}\n"
else
    spinner_start "mma cache compression"
    if [ -f "$MMA_AFSC_STAMP" ]; then
        find "$MMA_CACHE" -type f -name '*.html' -newer "$MMA_AFSC_STAMP" -print0 2>/dev/null \
            | xargs -0 -n 200 afsctool -c 2>/dev/null
    else
        afsctool -c "$MMA_CACHE" &>/dev/null
    fi
    touch "$MMA_AFSC_STAMP"
    spinner_stop
    printf "  ${GREEN}* mma cache: new entries APFS-compressed${NC}\n"
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

print_task "GeForce NOW CEF cache"
GFN_CACHE="$HOME/Library/Application Support/NVIDIA/GeForceNOW/CefCache"
if [ -d "$GFN_CACHE" ]; then
    if pgrep -x "GeForceNOW" > /dev/null; then
        printf "  ${DIM}* GeForce NOW: app is running, skipping${NC}\n"
    else
        spinner_start "GeForce NOW Chromium cache"
        gfn_before_kb=$(du -sk "$GFN_CACHE" 2>/dev/null | cut -f1)
        "$RM_CMD" -rf "$GFN_CACHE"/* 2>/dev/null
        gfn_after_kb=$(du -sk "$GFN_CACHE" 2>/dev/null | cut -f1)
        gfn_freed_kb=$(( gfn_before_kb - gfn_after_kb ))
        if [ "$gfn_freed_kb" -gt 0 ]; then
            spinner_stop "GeForce NOW: freed $(format_size $gfn_freed_kb)"
        else
            spinner_stop "GeForce NOW: nothing to clean"
        fi
    fi
else
    printf "  ${DIM}* GeForce NOW: not installed${NC}\n"
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

print_task "Re-locking Steam/Google autostart agents"
relock_autostart_agents

print_task "eq daemon log (cap at 500 lines)"
EQ_LOG="$HOME/Library/Logs/eq.log"
if [ -f "$EQ_LOG" ]; then
    eq_log_bytes=$(stat -f %z "$EQ_LOG" 2>/dev/null || echo 0)
    if [ "$eq_log_bytes" -gt 1048576 ]; then
        spinner_start "eq.log truncation"
        # launchd holds eq.log open; a rename would leave the daemon writing to the orphaned inode.
        if tail -n 500 "$EQ_LOG" > "$EQ_LOG.tmp" && cat "$EQ_LOG.tmp" > "$EQ_LOG" && rm -f "$EQ_LOG.tmp"; then
            spinner_stop "eq.log: capped to last 500 lines (was $(format_size $(( eq_log_bytes / 1024 ))))"
        else
            spinner_stop_error "eq.log: truncation failed"
        fi
    else
        printf "  ${DIM}* eq.log: under 1 MB, nothing to clean${NC}\n"
    fi
else
    printf "  ${DIM}* eq.log: not found${NC}\n"
fi

print_section "Dangling Symlinks"
report_broken_links

_free_bytes_after=$(df -k / | awk 'NR==2 {print $4}')
_freed_kb=$(( _free_bytes_after - _free_bytes_before ))
_free_gb=$(( _free_bytes_after / 1048576 ))

printf "\n${YELLOW}${BOLD}✨ All cleanup completed! Freed $(format_size $_freed_kb) (${_free_gb} GB available)${NC}\n"
