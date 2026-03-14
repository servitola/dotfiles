#!/bin/zsh
[[ ! -d "$PWD" ]] && {
    echo "❌ Current directory doesn't exist. Navigate to existing one, please"
    return 1
}

sudo -v -S

source ~/projects/dotfiles/zsh/functions.sh
source ~/projects/dotfiles/zsh/aliases.sh
source ~/projects/dotfiles/zsh/exports.sh

TRY_CLEAN="$HOME/projects/dotfiles/macos/helpers/try_to_clean_directory.sh"
TRY_CLEAN_PATTERN="$HOME/projects/dotfiles/macos/helpers/try_to_clean_by_pattern.sh"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_section() {
    printf "\n${BLUE}${BOLD}━━━ %s ━━━${NC}\n" "$1"
}

print_task() {
    printf "\n${GREEN}${BOLD}⚡${NC} ${BOLD}%s${NC}\n" "$1"
}

print_section "Apps Updates"

rm -rf "brew --cache" > /dev/null 2>&1
brew tap --repair
brew cu --all --yes --quiet
brew update
brew upgrade

print_task "Removing quarantine flags from updated applications"
brew_unquarantine

mas upgrade
brew cleanup --scrub

print_task "Set node22 is default"
brew unlink node 2>/dev/null || true
brew link --force --overwrite node@22

brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/brewfile

print_task "Updating VSCode extensions"
code --update-extensions

npm config set fund false
source ~/projects/dotfiles/npm/install-globals.sh
npm cache verify

uv python install 3.12
uv python pin 3.12
source ~/projects/dotfiles/python/install-globals.sh
source ~/projects/dotfiles/python/install-uv-tools.sh
uv cache prune

go clean -modcache

print_task "Update Appium Plugins"
appium plugin update installed

print_task "Updating .NET tools"
dotnet tool update -g dotnet-trace

print_task "Updating precommit hooks"
pre-commit autoupdate

print_section "System Maintenance"

print_task "Rebuilding zsh completion cache"
rm -f ~/.zcompdump* 2> /dev/null
chmod -R go-w "$(brew --prefix)/share" 2> /dev/null || true

print_task "Flushing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

print_task "Cleaning caches"
setopt rm_star_silent #turn off safe mode
"$TRY_CLEAN" ~/Library/Caches "Library Caches"
"$TRY_CLEAN" /Library/Caches "System Caches"
"$TRY_CLEAN" /Users/servitola/Library/Application\ Support/Caches "Application Support Caches"

print_task "Cleaning old Battle.net versions"
BATTLENET_VERSIONS_DIR="$HOME/Library/Application Support/Battle.net/Versions"
if [ -d "$BATTLENET_VERSIONS_DIR" ]; then
    # Count only actual version folders (Battle.net.XXXX pattern, excluding .app symlink)
    version_count=$(ls -1d "$BATTLENET_VERSIONS_DIR"/Battle.net.[0-9]* 2>/dev/null | grep -v '\.app$' | wc -l | tr -d ' ')
    if [ "$version_count" -gt 1 ]; then
        # Get oldest version folder by modification time
        oldest_version=$(ls -1dt "$BATTLENET_VERSIONS_DIR"/Battle.net.[0-9]* 2>/dev/null | grep -v '\.app$' | tail -1 | xargs basename)
        if [ -n "$oldest_version" ]; then
            rm -rf "$BATTLENET_VERSIONS_DIR/$oldest_version"
            echo "  * Removed old Battle.net version: $oldest_version"
        fi
    fi
fi

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
"$TRY_CLEAN" ~/Library/Application\ Support/Claude/Cache/Cache_Data "Claude Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Blizzard/Heroes\ of\ the\ Storm/GameLogs "HOTS Logs"
"$TRY_CLEAN" ~/Library/Application\ Support/discord/Cache/Cache_Data "Discord Cache"
"$TRY_CLEAN" ~/Library/Application\ Support/Windsurf/CachedData "Windsurf Cached Data"
"$TRY_CLEAN" ~/projects/cTraderDev/cTrader/Mobile.Touch.cTrader/bin "Work bins"
"$TRY_CLEAN" ~/Library/Application\ Support/Steam/logs "Steam Logs"
"$TRY_CLEAN" ~/Library/Logs/JetBrains "JetBrains IDE Logs"
"$TRY_CLEAN" ~/Library/Messages/Attachments "Messages Attachments"
"$TRY_CLEAN" ~/.npm/_logs "NPM Logs"
"$TRY_CLEAN" ~/.npm/_npx "NPX Cache"
"$TRY_CLEAN" ~/.cache/pre-commit "pre-commit Cache"
"$TRY_CLEAN" ~/.cache/puppeteer "Puppeteer Cache"


print_task "Cleaning system files"
"$TRY_CLEAN_PATTERN" . f "*.DS_Store" "DS_Store files"
"$TRY_CLEAN_PATTERN" . d ".AppleD*" "Apple Double files"

print_task "Cleaning Trash"
"$TRY_CLEAN_PATTERN" /Volumes d ".Trashes" "Volume Trashes"
"$TRY_CLEAN_PATTERN" /private/var/log/asl f "*.asl" "ASL Logs"
if [ -w ~/.Trash ]; then
    "$TRY_CLEAN" ~/.Trash "User Trash"
else
    if rm -rf ~/.Trash/* 2> /dev/null; then
        echo "  * User Trash: cleaned (with elevated permissions)"
    else
        echo "  * User Trash: ERROR - permission denied (protected by system)"
    fi
fi

setopt no_rm_star_silent #turn on safe mode back

print_section "Final Updates"

print_task "Updating TLDR cache"
tldr --update > /dev/null || echo "Error updating tldr cache"

print_task "Updating Bat cache"
bat cache --build > /dev/null || echo "Error updating bat cache"

print_task "Checking Android SDK licenses are accepted and Accept them"

yes | sdkmanager --licenses 2>&1 | grep -v "Warning: " > /dev/null || {
    error_code=$?
    if [ $error_code -ne 0 ] && [ $error_code -ne 141 ]; then
        echo "Error verifying Android SDK licenses"
    fi
}

print_task "Updating Powerlevel10k theme"
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

print_task "Updating Gruvbox wallpapers"
~/projects/dotfiles/macos/sync_gruvbox_wallpapers.sh

print_task "Updating Oh My Zsh"
zsh -ic "omz update"

print_task "Updating Atuin db (zsh history)"
atuin sync

printf "\n${YELLOW}${BOLD}✨ All updates and cleanup tasks completed!${NC}\n"

echo
source ~/projects/dotfiles/zsh/bin/random_ascii.sh

reload
