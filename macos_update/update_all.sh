#!/bin/zsh
# Update all packages and tools
#
# Strict mode (fail-fast policy): any failing step aborts the run, referencing
# an unset variable is an error, a pipeline fails if any component fails.
# Run as a child process (`zsh update_all.sh`) — never source into an
# interactive shell, or these options leak into it and break the prompt.
setopt err_exit no_unset pipe_fail

source ~/projects/dotfiles/macos_update/functions.sh

# Gruvbox colors
GREEN='\033[0;92m'      # Bright green
YELLOW='\033[0;33m'
BLUE='\033[0;94m'       # Bright blue
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
brew update
brew upgrade --greedy

print_task "Removing quarantine flags from updated applications"
brew_unquarantine

mas upgrade
brew cleanup --scrub

brew doctor || true  # [i9] tap-trust/deprecations make doctor exit non-zero; informational only, must not abort up
brew bundle dump --force --describe --file=~/projects/dotfiles/homebrew/brewfile

print_task "Updating VSCode extensions"
code --update-extensions

npm config set fund false
source ~/projects/dotfiles/npm/install-globals.sh
npm cache verify

uv python install 3.12
source ~/projects/dotfiles/python/install-globals.sh
source ~/projects/dotfiles/python/install-uv-tools.sh
source ~/projects/dotfiles/python/install-tts.sh
if pgrep -x uv > /dev/null; then
    echo "  * Skipping uv cache prune (uv is currently running)"
else
    uv cache prune
fi

print_task "Update Appium Plugins"
appium plugin update installed

print_task "Updating .NET tools"
dotnet tool update -g dotnet-trace

print_task "Updating precommit hooks"
pre-commit autoupdate

print_section "Docker Containers"

~/projects/dotfiles/docker/up.sh

print_section "Immich Sync"

print_task "Syncing local folders to Immich on i9"
~/projects/dotfiles/immich/sync.sh

print_section "LiteLLM Model Health"

print_task "Checking model availability across providers"
python3 ~/projects/dotfiles/litellm/scripts/check-models.py || echo "  * model-health check failed"

print_section "Tokens Savings"
rtk gain
print_task "Clearing macOS aerial wallpaper downloads"
# macOS keeps re-downloading multi-GB .mov aerial wallpapers; purge them every update.
# Currently-used aerial (if any) is locked and will be skipped silently.
AERIAL_DIR="$HOME/Library/Application Support/com.apple.wallpaper/aerials"
if [ -d "$AERIAL_DIR/videos" ]; then
    rm -f "$AERIAL_DIR"/videos/*.mov 2>/dev/null
    rm -f "$AERIAL_DIR"/thumbnails/* 2>/dev/null
fi

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
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" pull

print_task "Updating shared skill repos"
~/projects/dotfiles/claude-code/shared/skills-repos/update.sh

print_task "Updating Oh My Zsh"
zsh -ic "omz update"

print_task "Updating Atuin db (zsh history)"
atuin sync


print_task "Regenerating keyboard SVGs"
python3 ~/projects/dotfiles/docs/keyboard/generate.py 2>&1 | tail -3

print_task "Setting macOS appearance"
m appearance --highlightcolor grape

printf '\n%b✨ All updates completed!%b\n' "${YELLOW}${BOLD}" "${NC}"
