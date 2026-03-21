#!/bin/zsh
# Update all packages and tools

source ~/projects/dotfiles/zsh/functions.sh

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

print_section "Apps Updates"

rm -rf "$(brew --cache)" > /dev/null 2>&1
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
brew bundle dump --force --describe --file=~/projects/dotfiles/homebrew/brewfile

print_task "Updating VSCode extensions"
code --update-extensions

npm config set fund false
source ~/projects/dotfiles/npm/install-globals.sh
npm cache verify

uv python install 3.12
uv python pin 3.12
source ~/projects/dotfiles/python/install-globals.sh
source ~/projects/dotfiles/python/install-uv-tools.sh
if pgrep -x uv > /dev/null; then
    echo "  * Skipping uv cache prune (uv is currently running)"
else
    uv cache prune
fi

go clean -modcache

print_task "Update Appium Plugins"
appium plugin update installed

print_task "Updating .NET tools"
dotnet tool update -g dotnet-trace

print_task "Updating precommit hooks"
pre-commit autoupdate

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

print_task "Updating Oh My Zsh"
zsh -ic "omz update"

print_task "Updating Atuin db (zsh history)"
atuin sync


print_task "Setting macOS appearance"
m appearance --highlightcolor grape

printf "\n${YELLOW}${BOLD}✨ All updates completed!${NC}\n"
