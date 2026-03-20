#!/bin/zsh
# Main script: runs updates, then cleanup, then shows random ASCII art

SCRIPT_DIR="$HOME/projects/dotfiles/macos"

# Gruvbox colors
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

echo "${GREEN}${BOLD}🚀 Starting full update and cleanup...${NC}"
echo

echo "${GREEN}📦 Running updates...${NC}"
source "$SCRIPT_DIR/update_all.sh"

echo

echo "${YELLOW}🧹 Running cleanup...${NC}"
source "$SCRIPT_DIR/../cleanup/cleanup_all.sh"

echo

source ~/projects/dotfiles/zsh/bin/random_ascii.sh

echo "${GREEN}${BOLD}🔄 Reloading shell to apply changes...${NC}"
exec zsh
