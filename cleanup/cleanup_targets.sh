#!/bin/zsh
# List of directories and patterns to clean
# Requires: helpers.sh, try_clean.sh

# --- Caches ---

try_clean ~/Library/Caches "Library Caches"
try_clean /Library/Caches "System Caches"
try_clean ~/Library/Application\ Support/Caches "Application Support Caches"

# --- Gaming ---

BATTLENET_VERSIONS_DIR="$HOME/Library/Application Support/Battle.net/Versions"
BATTLENET_KEEP=2
if [ -d "$BATTLENET_VERSIONS_DIR" ]; then
    all_versions=($(ls -1d "$BATTLENET_VERSIONS_DIR"/Battle.net.[0-9]* 2>/dev/null | grep -v '\.app$' | sort -t. -k3 -n))
    total_count=${#all_versions[@]}
    if [ "$total_count" -gt "$BATTLENET_KEEP" ]; then
        remove_count=$(( total_count - BATTLENET_KEEP ))
        old_versions=("${all_versions[@]:0:$remove_count}")
        spinner_start "Battle.net old versions"
        total_size_kb=0
        for version_dir in "${old_versions[@]}"; do
            if [ -d "$version_dir" ]; then
                dir_kb=$(du -sk "$version_dir" 2>/dev/null | cut -f1)
                total_size_kb=$(( total_size_kb + dir_kb ))
                "$RM_CMD" -rf "$version_dir"
            fi
        done
        spinner_stop "Battle.net old versions: cleaned ($remove_count of $total_count, kept $BATTLENET_KEEP newest, $(format_size $total_size_kb))"
    else
        printf "  ${DIM}* Battle.net old versions: $total_count found, keeping all (≤$BATTLENET_KEEP)${NC}\n"
    fi
else
    printf "  ${DIM}* Battle.net old versions: not found${NC}\n"
fi

try_clean ~/Library/Application\ Support/Battle.net/Logs "Battle.net Logs"
try_clean ~/Library/Application\ Support/Blizzard/Heroes\ of\ the\ Storm/GameLogs "HOTS Logs"
try_clean ~/Library/Application\ Support/heroic/Cache "Heroic Cache"
try_clean ~/Library/Application\ Support/heroic/images-cache "Heroic Images Cache"
try_clean ~/Library/Application\ Support/Steam/logs "Steam Logs"
try_clean ~/Library/Application\ Support/Steam/appcache "Steam App Cache"
try_clean ~/Library/Application\ Support/Steam/depotcache "Steam Depot Cache"
try_clean ~/Library/Application\ Support/Steam/steamapps/shadercache "Steam Shader Cache"
try_clean ~/Library/Application\ Support/Steam/steamapps/temp "Steam Temp"
try_clean ~/Library/Application\ Support/Steam/steamapps/download "Steam Downloads"

# --- Development ---

try_clean ~/Library/Caches/JetBrains "JetBrains IDE Caches"
try_clean ~/Library/Logs/JetBrains "JetBrains IDE Logs"
try_clean ~/Library/Developer/Xcode/Archives "Xcode Archives (old builds)"
try_clean ~/Library/Developer/Xcode/DerivedData "Xcode DerivedData"
try_clean ~/Library/Logs/CoreSimulator "Xcode CoreSimulator Logs"
try_clean ~/Library/Application\ Support/Code/logs "VSCode Logs"
try_clean ~/Library/Application\ Support/Code/CachedData "VSCode Cached Data"
try_clean ~/Library/Application\ Support/Windsurf/CachedData "Windsurf Cached Data"
try_clean ~/Library/Application\ Support/Windsurf/logs "Windsurf Logs"
try_clean ~/.android/cache "Android SDK Cache"
try_clean ~/.gradle/caches "Gradle Cache"
try_clean ~/.local/share/NuGet/v3-cache "NuGet Cache"
try_clean ~/.npm/_logs "NPM Logs"
try_clean ~/.npm/_npx "NPX Cache"
try_clean ~/.cache/pre-commit "pre-commit Cache"
try_clean ~/.cache/puppeteer "Puppeteer Cache"
try_clean ~/projects/cTraderDev/cTrader/Mobile.Touch.cTrader/bin "Work bins"
try_clean /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs "XDB Logs"

# --- Applications ---

try_clean ~/Library/Application\ Support/discord/Cache "Discord Cache"
try_clean ~/Library/Application\ Support/discord/Cache/Cache_Data "Discord Cache Data"
try_clean ~/Library/Application\ Support/obsidian/Cache "Obsidian Cache"
try_clean ~/Library/Application\ Support/obsidian/Code\ Cache "Obsidian Code Cache"
try_clean ~/Library/Application\ Support/obsidian/DawnGraphiteCache "Obsidian GraphiteCache"
try_clean ~/Library/Application\ Support/obsidian/DawnWebGPUCache "Obsidian WebGPU Cache"
try_clean ~/Library/Application\ Support/Claude/Cache/Cache_Data "Claude Cache"
try_clean ~/Library/Application\ Support/Moises/Cache/Cache_Data "Moises Cache"
try_clean ~/Library/Application\ Support/Yandex/YandexBrowser/Resources/extension/cache_2 "Yandex Browser Extension Cache"
try_clean ~/Library/Application\ Support/Google/GoogleUpdater/crx_cache "Google Updater Cache"
try_clean ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files "Adobe Media Cache"

# --- System ---

try_clean ~/Library/Application\ Support/CrashReporter "Crash reports"
try_clean ~/Library/Metadata/SpotlightKnowledgeEvents "Spotlight Knowledge Events"
try_clean ~/Library/Logs "Library Logs"
try_clean ~/Library/Messages/Attachments "Messages Attachments"
try_clean /System/Volumes/Data/.PreviousSystemInformation "Previous System Information"
try_clean /Library/Logs/DiagnosticReports "System Diagnostic Reports"

if [ -d /cores ] && [ "$(ls -A /cores 2>/dev/null)" ]; then
    spinner_start "Core dumps"
    cores_kb=$(du -sk /cores 2>/dev/null | cut -f1)
    sudo "$RM_CMD" -rf /cores/* </dev/null
    spinner_stop "Core dumps: cleaned ($(format_size $cores_kb))"
else
    printf "  ${DIM}* Core dumps: nothing to clean${NC}\n"
fi

# --- Patterns ---

try_clean_pattern ~ f ".DS_Store" "DS_Store files"
try_clean_pattern . d ".AppleD*" "Apple Double files"
