# =============================================================================
# .zprofile - Login Shell Configuration (runs BEFORE .zshrc)
# =============================================================================

# Initialize Homebrew environment
eval "$(/opt/homebrew/bin/brew shellenv)"

# Environment Variables & Custom Paths
source ~/projects/dotfiles/zsh/exports.sh
