#!/bin/zsh
# Main script: runs updates, then cleanup

# Gruvbox colors
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo "${GREEN}📦 Running updates...${NC}"
source "$HOME/projects/dotfiles/macos_update/update_all.sh"

echo

echo "${YELLOW}🧹 Running cleanup...${NC}"
source "$HOME/projects/dotfiles/macos_cleanup/cleanup_all.sh"

echo

source "$HOME/projects/dotfiles/zsh/bin/random_ascii.sh"

echo "${GREEN}${BOLD}🔄 Reloading shell to apply changes...${NC}"
exec zsh
