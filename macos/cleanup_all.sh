#!/bin/zsh
# Clean all caches, logs, and temporary files

TRY_CLEAN="$HOME/projects/dotfiles/macos/helpers/try_to_clean_directory.sh"
TRY_CLEAN_PATTERN="$HOME/projects/dotfiles/macos/helpers/try_to_clean_by_pattern.sh"
source "$HOME/projects/dotfiles/macos/helpers/spinner.sh"

# Gruvbox colors
RED='\033[0;31m'
GREEN='\033[0;92m'      # Bright green
YELLOW='\033[0;33m'
BLUE='\033[0;94m'       # Bright blue
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

print_section() {
    printf "\n${BLUE}${BOLD}━━━ %s ━━━${NC}\n" "$1"
}

print_task() {
    printf "\n${GREEN}${BOLD}⚡${NC} ${BOLD}%s${NC}\n" "$1"
}

# Cache sudo credentials upfront so cleanup isn't interrupted by password prompts
sudo -v

_free_bytes_before=$(df -k / | awk 'NR==2 {print $4}')

print_section "System Maintenance"

print_task "Rebuilding zsh completion cache"
rm -f ~/.zcompdump* 2> /dev/null
chmod -R go-w "$(brew --prefix)/share" 2> /dev/null || true

print_task "Flushing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

print_task "Cleaning caches"
setopt rm_star_silent
"$TRY_CLEAN" ~/Library/Caches "Library Caches"
"$TRY_CLEAN" /Library/Caches "System Caches"
"$TRY_CLEAN" ~/Library/Application\ Support/Caches "Application Support Caches"

BATTLENET_VERSIONS_DIR="$HOME/Library/Application Support/Battle.net/Versions"
if [ -d "$BATTLENET_VERSIONS_DIR" ]; then
    old_versions=($(ls -1d "$BATTLENET_VERSIONS_DIR"/Battle.net.[0-9]* 2>/dev/null | grep -v '\.app$'))
    version_count=${#old_versions[@]}
    if [ "$version_count" -gt 0 ]; then
        spinner_start "Battle.net old versions"
        total_size_kb=0
        for version_dir in "${old_versions[@]}"; do
            if [ -d "$version_dir" ]; then
                dir_kb=$(du -sk "$version_dir" 2>/dev/null | cut -f1)
                total_size_kb=$(( total_size_kb + dir_kb ))
                rm -rf "$version_dir"
            fi
        done
        if [ "$total_size_kb" -ge 1048576 ]; then
            bnet_size="$(( total_size_kb / 1048576 )) GB"
        elif [ "$total_size_kb" -ge 1024 ]; then
            bnet_size="$(( total_size_kb / 1024 )) MB"
        else
            bnet_size="${total_size_kb} KB"
        fi
        spinner_stop "Battle.net old versions: cleaned ($version_count versions, $bnet_size)"
    else
        printf "  ${DIM}* Battle.net old versions: nothing to clean${NC}\n"
    fi
else
    printf "  ${DIM}* Battle.net old versions: not found${NC}\n"
fi

"$TRY_CLEAN" ~/Library/Application\ Support/Battle.net/Logs "HOTS Log"
"$TRY_CLEAN" ~/Library/Application\ Support/CrashReporter "Crash reports"
"$TRY_CLEAN" ~/Library/Application\ Support/heroic/Cache "Heroic Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/heroic/images-cache "Heroic Images Cache"

"$TRY_CLEAN" ~/Library/Metadata/SpotlightKnowledgeEvents "Spotlight Knowledge Events"

"$TRY_CLEAN" ~/Library/Caches/JetBrains "JetBrains IDE Caches"
"$TRY_CLEAN" ~/Library/Developer/Xcode/Archives "Xcode Archives (old builds)"
"$TRY_CLEAN" ~/Library/Logs/CoreSimulator "Xcode CoreSimulator Logs"
"$TRY_CLEAN" ~/.android/cache "Android SDK Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/discord/Cache "Discord Cache"
"$TRY_CLEAN" ~/.gradle/caches "Gradle Cache"
"$TRY_CLEAN" ~/Library/Logs "Library Logs"
"$TRY_CLEAN" ~/Library/Developer/Xcode/DerivedData "Xcode DerivedData"
"$TRY_CLEAN" /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs "XDB Logs"
"$TRY_CLEAN" ~/.local/share/NuGet/v3-cache "NuGet Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Moises/Cache/Cache_Data "Moises Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Code/logs "VSCode Logs"
"$TRY_CLEAN" ~/Library/Application\ Support/Code/CachedData "VSCode Cached Data"
"$TRY_CLEAN" ~/Library/Application\ Support/Yandex/YandexBrowser/Resources/extension/cache_2 "Yandex Browser Extension Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Google/GoogleUpdater/crx_cache "Google Updater Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files "Adobe Media Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/obsidian/Cache "Obsidian Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/obsidian/Code\ Cache "Obsidian Code Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/obsidian/DawnGraphiteCache "Obsidian GraphiteCache"
"$TRY_CLEAN" ~/Library/Application\ Support/obsidian/DawnWebGPUCache "Obsidian WebGPU Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Claude/Cache/Cache_Data "Claude Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Blizzard/Heroes\ of\ the\ Storm/GameLogs "HOTS Logs"
"$TRY_CLEAN" ~/Library/Application\ Support/discord/Cache/Cache_Data "Discord Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Windsurf/CachedData "Windsurf Cached Data"
"$TRY_CLEAN" ~/Library/Application\ Support/Windsurf/logs "VSCode Logs"
"$TRY_CLEAN" ~/projects/cTraderDev/cTrader/Mobile.Touch.cTrader/bin "Work bins"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/logs "Steam Logs"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/appcache "Steam App Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/depotcache "Steam Depot Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/steamapps/shadercache "Steam Shader Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/steamapps/temp "Steam Temp"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/steamapps/download "Steam Downloads"
"$TRY_CLEAN" ~/Library/Logs/JetBrains "JetBrains IDE Logs"
"$TRY_CLEAN" ~/Library/Messages/Attachments "Messages Attachments"
"$TRY_CLEAN" ~/.npm/_logs "NPM Logs"
"$TRY_CLEAN" ~/.npm/_npx "NPX Cache"
"$TRY_CLEAN" ~/.cache/pre-commit "pre-commit Cache"
"$TRY_CLEAN" ~/.cache/puppeteer "Puppeteer Cache"
"$TRY_CLEAN" /System/Volumes/Data/.PreviousSystemInformation "Previous System Information"
"$TRY_CLEAN" /Library/Logs/DiagnosticReports "System Diagnostic Reports"

if [ -d /cores ] && [ "$(ls -A /cores 2>/dev/null)" ]; then
    spinner_start "Core dumps"
    cores_kb=$(du -sk /cores 2>/dev/null | cut -f1)
    sudo realrm -rf /cores/*
    if [ "$cores_kb" -ge 1048576 ]; then
        cores_size="$(( cores_kb / 1048576 )) GB"
    elif [ "$cores_kb" -ge 1024 ]; then
        cores_size="$(( cores_kb / 1024 )) MB"
    else
        cores_size="${cores_kb} KB"
    fi
    spinner_stop "Core dumps: cleaned ($cores_size)"
else
    printf "  ${DIM}* Core dumps: nothing to clean${NC}\n"
fi

"$TRY_CLEAN_PATTERN" ~ f ".DS_Store" "DS_Store files"
"$TRY_CLEAN_PATTERN" . d ".AppleD*" "Apple Double files"

print_task "Cleaning Homebrew cask installers"
cask_installers_count=$(find /opt/homebrew/Caskroom -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$cask_installers_count" -gt 0 ]; then
    spinner_start "Cask installers"
    cask_size_kb=$(find /opt/homebrew/Caskroom -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    find /opt/homebrew/Caskroom -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" -delete 2>/dev/null
    if [ "$cask_size_kb" -ge 1048576 ]; then
        cask_size="$(( cask_size_kb / 1048576 )) GB"
    elif [ "$cask_size_kb" -ge 1024 ]; then
        cask_size="$(( cask_size_kb / 1024 )) MB"
    else
        cask_size="${cask_size_kb} KB"
    fi
    spinner_stop "Cask installers: cleaned ($cask_installers_count files, $cask_size)"
else
    printf "  ${DIM}* Cask installers: nothing to clean${NC}\n"
fi

print_task "Cleaning Trash"
"$TRY_CLEAN_PATTERN" /Volumes d ".Trashes" "Volume Trashes"
"$TRY_CLEAN_PATTERN" /private/var/log/asl f "*.asl" "ASL Logs"
if [ -w ~/.Trash ]; then
    "$TRY_CLEAN" ~/.Trash "User Trash"
else
    trash_kb=$(du -sk ~/.Trash 2>/dev/null | cut -f1)
    if [ -n "$trash_kb" ] && [ "$trash_kb" -gt 0 ]; then
        spinner_start "User Trash"
        if realrm -rf ~/.Trash/* 2> /dev/null; then
            if [ "$trash_kb" -ge 1048576 ]; then
                trash_size="$(( trash_kb / 1048576 )) GB"
            elif [ "$trash_kb" -ge 1024 ]; then
                trash_size="$(( trash_kb / 1024 )) MB"
            else
                trash_size="${trash_kb} KB"
            fi
            spinner_stop "User Trash: cleaned ($trash_size)"
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
if [ "$_freed_kb" -gt 1048576 ]; then
    _freed="$(( _freed_kb / 1048576 )) GB"
elif [ "$_freed_kb" -gt 1024 ]; then
    _freed="$(( _freed_kb / 1024 )) MB"
else
    _freed="${_freed_kb} KB"
fi
_free_gb=$(( _free_bytes_after / 1048576 ))

printf "\n${YELLOW}${BOLD}✨ All cleanup completed! Freed ${_freed} (${_free_gb} GB available)${NC}\n"
