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
    printf "\n${BLUE}${BOLD}=== %s ===${NC}\n" "$1"
}

print_task() {
    printf "${GREEN}➜ %s...${NC}\n" "$1"
}

print_section "System Updates"

print_task "Updating XCode tools"
sudo softwareupdate -i -a
command -v xcode-select >/dev/null 2>&1 || xcode-select --install

print_task "Updating Homebrew packages"
rm -rf "brew --cache" >/dev/null 2>&1
brew tap --repair
brew cu --all --yes --quiet --no-quarantine
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

print_task "Updating .NET tools"
dotnet tool update -g dotnet-trace

print_section "System Maintenance"

print_task "Flushing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

print_task "Cleaning system caches"
setopt rm_star_silent #turn off safe mode
rm -rf ~/Library/Caches/* >/dev/null 2>&1
rm -rf /Library/Caches/* >/dev/null 2>&1

print_task "Clearing system logs"
find ~/Library/Logs -type f -name '*.log' -delete >/dev/null 2>&1
find ~/Library/Logs -type f -name '*.log.0' -delete >/dev/null 2>&1
rm -rf ~/Library/Developer/Xcode/DerivedData/* >/dev/null 2>&1
rm -rf /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs/* >/dev/null 2>&1
rm -rf ~/.local/share/NuGet/v3-cache/* >/dev/null 2>&1

print_task "Cleaning .DS_Store files"
find . -type f -name '*.DS_Store' -delete >/dev/null 2>&1
print_task "Cleaning Apple-specific files"
find . -type d -name '.AppleD*' -exec rm -rf {} \; >/dev/null 2>&1

print_task "Emptying Trash"
rm -rf /Volumes/*/.Trashes >/dev/null 2>&1
rm -rf /private/var/log/asl/*.asl >/dev/null 2>&1
rm -rf ~/.Trash/* >/dev/null 2>&1

setopt no_rm_star_silent #turn on safe mode back

print_section "Additional Updates"

print_task "Updating tldr cache"
tldr --update >/dev/null || echo "Error updating tldr cache"

print_task "Verifying Android SDK licenses"
sdkmanager --licenses >/dev/null || echo "Error verifying Android SDK licenses"

reload

print_task "Updating Oh My Zsh"
zsh -ic "omz update"
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

purge

reload

printf "\n${YELLOW}${BOLD}✨ All updates and cleanup tasks completed!${NC}\n\n"
