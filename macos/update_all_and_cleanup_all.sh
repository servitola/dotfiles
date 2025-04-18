#!/bin/zsh
sudo -v

source ~/projects/dotfiles/zsh/functions.sh
source ~/projects/dotfiles/zsh/aliases.sh

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

rm -rf "brew --cache" >/dev/null 2>&1
brew tap --repair
brew cu --all --yes --quiet --no-quarantine
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/brewfile

print_task "Updating .NET tools"
dotnet tool update -g dotnet-trace

print_section "System Maintenance"

print_task "Flushing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

print_task "Cleaning caches"
setopt rm_star_silent #turn off safe mode
rm -rf ~/Library/Caches/* >/dev/null 2>&1
rm -rf /Library/Caches/* >/dev/null 2>&1

print_task "Cleaning logs"
find ~/Library/Logs -type f -name '*.log' -delete >/dev/null 2>&1
find ~/Library/Logs -type f -name '*.log.0' -delete >/dev/null 2>&1
rm -rf ~/Library/Developer/Xcode/DerivedData/* >/dev/null 2>&1
rm -rf /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs/* >/dev/null 2>&1
rm -rf ~/.local/share/NuGet/v3-cache/* >/dev/null 2>&1

print_task "Cleaning system files"
find . -type f -name '*.DS_Store' -delete >/dev/null 2>&1
find . -type d -name '.AppleD*' -exec rm -rf {} \; >/dev/null 2>&1

print_task "Cleaning Trash"
rm -rf /Volumes/*/.Trashes >/dev/null 2>&1
rm -rf /private/var/log/asl/*.asl >/dev/null 2>&1
rm -rf ~/.Trash/* >/dev/null 2>&1

setopt no_rm_star_silent #turn on safe mode back

print_section "Final Updates"

print_task "Updating TLDR cache"
tldr --update >/dev/null || echo "Error updating tldr cache"

print_task "Checking Android SDK"

sdkmanager --licenses --quiet 2>&1 | grep -v "Warning: " >/dev/null || {
    error_code=$?
    if [ $error_code -ne 0 ] && [ $error_code -ne 141 ]; then
        echo "Error verifying Android SDK licenses"
    fi
}

reload

print_task "Updating Oh My Zsh"
zsh -ic "omz update"
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

cd $(HOME)/projects/gruvbox-wallpapers && git fetch --depth=1 origin && git reset --hard origin/main;

purge

reload

printf "\n${YELLOW}${BOLD}✨ All updates and cleanup tasks completed!${NC}\n\n"
