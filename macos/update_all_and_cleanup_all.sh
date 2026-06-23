#!/bin/zsh
# Main script: runs updates, then cleanup

# Gruvbox colors
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo "${GREEN}📦 Running updates...${NC}"
zsh "$HOME/projects/dotfiles/macos_update/update_all.sh" || {
    echo "${RED}${BOLD}✗ Update failed — skipping cleanup and shell reload.${NC}"
    return 1
}

echo

echo "${YELLOW}🧹 Running cleanup...${NC}"
# AGGRESSIVE is passed explicitly: `AGGRESSIVE=true up` sets it as a shell
# parameter of the sourcing shell, which child processes don't inherit
AGGRESSIVE="${AGGRESSIVE:-}" zsh "$HOME/projects/dotfiles/macos_cleanup/cleanup_all.sh" || {
    echo "${RED}${BOLD}✗ Cleanup failed — skipping shell reload.${NC}"
    return 1
}

echo

source "$HOME/projects/dotfiles/zsh/bin/random_ascii.sh"

echo "${GREEN}${BOLD}🔄 Reloading shell to apply changes...${NC}"
exec zsh
