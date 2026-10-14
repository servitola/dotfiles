#!/bin/zsh
# Main script: runs updates, then cleanup

# Gruvbox colors
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# One password for the whole run: sudo forgets it after 5 minutes, so the
# casks of a long brew upgrade and then the cleanup each asked again.
sudo -v || return 1
while sudo -n true 2>/dev/null; do sleep 50; done &!
_up_sudo_keeper=$!

# Steps append one line per problem here; it is printed once, at the end.
export UP_ATTENTION=$(mktemp -t up-attention)

_up_finish() {
    kill $_up_sudo_keeper 2>/dev/null
    if [[ -s $UP_ATTENTION ]]; then
        echo "\n${YELLOW}${BOLD}━━━ Требует внимания ━━━${NC}"
        sed 's/^/  • /' "$UP_ATTENTION"
    fi
    rm -f "$UP_ATTENTION"
    unset UP_ATTENTION
}

echo "${GREEN}📦 Running updates...${NC}"
zsh "$HOME/projects/dotfiles/macos_update/update_all.sh" || {
    echo "${RED}${BOLD}✗ Update failed — skipping cleanup and shell reload.${NC}"
    _up_finish
    return 1
}

echo

echo "${YELLOW}🧹 Running cleanup...${NC}"
zsh "$HOME/projects/dotfiles/macos_cleanup/cleanup_all.sh" || {
    echo "${RED}${BOLD}✗ Cleanup failed — skipping shell reload.${NC}"
    _up_finish
    return 1
}

echo

source "$HOME/projects/dotfiles/zsh/bin/random_ascii.sh"
_up_finish

echo "${GREEN}${BOLD}🔄 Reloading shell to apply changes...${NC}"
exec zsh
