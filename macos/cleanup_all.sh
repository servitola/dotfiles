#!/bin/zsh
# Clean all caches, logs, and temporary files

TRY_CLEAN="$HOME/projects/dotfiles/macos/helpers/try_to_clean_directory.sh"
TRY_CLEAN_PATTERN="$HOME/projects/dotfiles/macos/helpers/try_to_clean_by_pattern.sh"

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
"$TRY_CLEAN" /Users/servitola/Library/Application\ Support/Caches "Application Support Caches"

print_task "Cleaning old Battle.net versions"
BATTLENET_VERSIONS_DIR="$HOME/Library/Application Support/Battle.net/Versions"
if [ -d "$BATTLENET_VERSIONS_DIR" ]; then
    old_versions=($(ls -1d "$BATTLENET_VERSIONS_DIR"/Battle.net.[0-9]* 2>/dev/null | grep -v '\.app$'))
    version_count=${#old_versions[@]}
    if [ "$version_count" -gt 0 ]; then
        for version_dir in "${old_versions[@]}"; do
            if [ -d "$version_dir" ]; then
                version_name=$(basename "$version_dir")
                version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
                rm -rf "$version_dir"
                echo "  * Removed old Battle.net version: $version_name ($version_size)"
            fi
        done
    fi
fi

"$TRY_CLEAN" ~/Library/Application\ Support/Battle.net/Logs "HOTS Log"
"$TRY_CLEAN" ~/Library/Application\ Support/CrashReporter "Crash reports"
"$TRY_CLEAN" ~/Library/Application\ Support/heroic/Cache "Heroic Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/heroic/images-cache "Heroic Images Cache"

print_task "Cleaning Spotlight Knowledge Events"
SPOTLIGHT_KNOWLEDGE_DIR="$HOME/Library/Metadata/SpotlightKnowledgeEvents"
if [ -d "$SPOTLIGHT_KNOWLEDGE_DIR" ]; then
    spotlight_size=$(du -sh "$SPOTLIGHT_KNOWLEDGE_DIR" 2>/dev/null | cut -f1)
    if [ -n "$spotlight_size" ]; then
        rm -rf "$SPOTLIGHT_KNOWLEDGE_DIR"/*
        echo "  * Cleaned Spotlight Knowledge Events (was: $spotlight_size)"
    fi
fi

"$TRY_CLEAN" ~/Library/Caches/JetBrains "JetBrains IDE Caches"
"$TRY_CLEAN" ~/Library/Developer/Xcode/Archives "Xcode Archives (old builds)"
"$TRY_CLEAN" ~/.android/cache "Android SDK Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/discord/Cache "Discord Cache"

if [ -d ~/.gradle/caches ]; then
    gradle_cache_size=$(du -sh ~/.gradle/caches 2>/dev/null | cut -f1)
    find ~/.gradle/caches -type d -name "*-*" -mtime +30 -exec rm -rf {} + 2>/dev/null
    echo "  * Gradle Cache: cleaned old versions (was: $gradle_cache_size)"
fi

print_task "Cleaning logs"
"$TRY_CLEAN" ~/Library/Logs "Library Logs"
"$TRY_CLEAN" ~/Library/Developer/Xcode/DerivedData "Xcode DerivedData"
"$TRY_CLEAN" /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs "XDB Logs"
"$TRY_CLEAN" ~/.local/share/NuGet/v3-cache "NuGet Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Moises/Cache/Cache_Data "Moises Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Code/logs "VSCode Logs"
"$TRY_CLEAN" ~/Library/Application\ Support/Code/CachedData "VSCode Cached Data"
"$TRY_CLEAN" ~/Library/Application\ Support/Yandex/YandexBrowser/Resources/extension/cache_2 "Yandex Browser Extension Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Google/GoogleUpdater/crx_cache "Google Updater Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Claude/Cache/Cache_Data "Claude Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Blizzard/Heroes\ of\ the\ Storm/GameLogs "HOTS Logs"
"$TRY_CLEAN" ~/Library/Application\ Support/discord/Cache/Cache_Data "Discord Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Windsurf/CachedData "Windsurf Cached Data"
"$TRY_CLEAN" ~/Library/Application\ Support/Windsurf/logs "VSCode Logs"
"$TRY_CLEAN" ~/projects/cTraderDev/cTrader/Mobile.Touch.cTrader/bin "Work bins"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/logs "Steam Logs"
"$TRY_CLEAN" ~/Library/Logs/JetBrains "JetBrains IDE Logs"
"$TRY_CLEAN" ~/Library/Messages/Attachments "Messages Attachments"
"$TRY_CLEAN" ~/.npm/_logs "NPM Logs"
"$TRY_CLEAN" ~/.npm/_npx "NPX Cache"
"$TRY_CLEAN" ~/.cache/pre-commit "pre-commit Cache"
"$TRY_CLEAN" ~/.cache/puppeteer "Puppeteer Cache"
"$TRY_CLEAN" /System/Volumes/Data/.PreviousSystemInformation "Previous System Information"
"$TRY_CLEAN" /Library/Logs/DiagnosticReports "System Diagnostic Reports"

print_task "Cleaning core dumps"
if [ -d /cores ] && [ "$(ls -A /cores 2>/dev/null)" ]; then
    sudo realrm -rf /cores/*
    echo "  * Core dumps: cleaned"
fi

print_task "Cleaning system files"
"$TRY_CLEAN_PATTERN" ~ f ".DS_Store" "DS_Store files"
"$TRY_CLEAN_PATTERN" . d ".AppleD*" "Apple Double files"

print_task "Cleaning Homebrew cask installers"
cask_installers_count=$(find /opt/homebrew/Caskroom -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$cask_installers_count" -gt 0 ]; then
    cask_installers_size=$(du -sh /opt/homebrew/Caskroom 2>/dev/null | cut -f1)
    find /opt/homebrew/Caskroom -type f \( -name "*.pkg" -o -name "*.dmg" -o -name "*.zip" -o -name "*.tar.gz" \) ! -path "*/.metadata/*" -delete 2>/dev/null
    cask_installers_size_after=$(du -sh /opt/homebrew/Caskroom 2>/dev/null | cut -f1)
    echo "  * Cask installers: cleaned ($cask_installers_count files, freed space)"
fi

print_task "Cleaning Trash"
"$TRY_CLEAN_PATTERN" /Volumes d ".Trashes" "Volume Trashes"
"$TRY_CLEAN_PATTERN" /private/var/log/asl f "*.asl" "ASL Logs"
if [ -w ~/.Trash ]; then
    "$TRY_CLEAN" ~/.Trash "User Trash"
else
    if realrm -rf ~/.Trash/* 2> /dev/null; then
        echo "  * User Trash: cleaned (with elevated permissions)"
    else
        echo "  * User Trash: ERROR - permission denied (protected by system)"
    fi
fi

setopt no_rm_star_silent

printf "\n${YELLOW}${BOLD}✨ All cleanup completed!${NC}\n"
