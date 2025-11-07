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
    printf "${GREEN}${BOLD}⚡${NC} ${BOLD}%s${NC}\n" "$1"
}

print_section "Apps Updates"

rm -rf "brew --cache" > /dev/null 2>&1
brew tap --repair
brew cu --all --yes --quiet --no-quarantine
brew update
brew upgrade
# List mas apps to avoid bug with non updating apps from AppStore
mas list > /dev/null 2>&1
mas upgrade
brew cleanup
brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/brewfile

source ~/projects/dotfiles/npm/install-globals.sh

uv python install 3.12
uv python pin 3.12
uv tool install faster-whisper
uv tool install whisper-ctranslate2
source ~/projects/dotfiles/python/install-globals.sh

print_task "Update Appium Plugins"
appium plugin update installed

print_task "Updating .NET tools"
dotnet tool update -g dotnet-trace

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

print_task "Cleaning logs"
"$TRY_CLEAN_PATTERN" ~/Library/Logs f "*.log" "Log files"
"$TRY_CLEAN_PATTERN" ~/Library/Logs f "*.log.0" "Rotated log files"
"$TRY_CLEAN" ~/Library/Developer/Xcode/DerivedData "Xcode DerivedData"
"$TRY_CLEAN" /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs "XDB Logs"
"$TRY_CLEAN" ~/.local/share/NuGet/v3-cache "NuGet Cache"

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
