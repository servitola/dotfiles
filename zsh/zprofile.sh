# =============================================================================
# .zprofile - Login Shell Configuration (runs BEFORE .zshrc)
# =============================================================================
# This file is executed for LOGIN shells (Terminal/iTerm2 default behavior).
# On macOS, the shell startup order is:
#   1. .zprofile (this file)
#   2. .zshrc
#   3. .zlogin
#
# CRITICAL: Homebrew path configuration MUST happen here, not in .zshrc
# Reason: oh-my-zsh calls compinit during sourcing, and compinit needs FPATH
#         to be already populated with Homebrew's completion directories.
# =============================================================================

# Initialize Homebrew environment
# This single command sets up:
#   - HOMEBREW_PREFIX, HOMEBREW_CELLAR, HOMEBREW_REPOSITORY
#   - PATH:     Adds /opt/homebrew/bin and /opt/homebrew/sbin
#   - MANPATH:  Adds /opt/homebrew/share/man for manual pages
#   - INFOPATH: Adds /opt/homebrew/share/info for info pages
#   - FPATH:    Adds /opt/homebrew/share/zsh/site-functions for completions ⭐
#
# FPATH is critical - it tells compinit where to find completion functions.
# Without this, you lose completions for ALL Homebrew-installed CLI tools.
#
# The eval automatically detects your architecture:
#   - Apple Silicon: /opt/homebrew
#   - Intel:         /usr/local
#
# NOTE: We use 'brew' command directly (not hardcoded path) because:
#   - Homebrew installer adds brew to PATH in /etc/paths.d/
#   - Works on both Intel and ARM Macs
#   - If brew isn't found, shell will show clear error
eval "$(brew shellenv)"

# Load environment variables and custom PATH additions
# These are additions BEYOND what Homebrew provides
source ~/projects/dotfiles/zsh/exports.sh
