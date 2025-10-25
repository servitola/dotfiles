# =============================================================================
# .zshrc - Interactive Shell Configuration
# =============================================================================

# Powerlevel10k Instant Prompt
# Should stay close to the top of .zshrc for optimal performance
ZSH_THEME="powerlevel10k/powerlevel10k"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Auto-update Homebrew every 24 hours when running brew commands
export HOMEBREW_AUTO_UPDATE_SECS="86400"

# Disable telemetry for Claude Code
export CLAUDE_CODE_ENABLE_TELEMETRY=0

# Locale Configuration
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# -----------------------------------------------------------------------------
# Plugin Configuration (BEFORE oh-my-zsh loads)
# -----------------------------------------------------------------------------
# Define which oh-my-zsh plugins to load
source ~/projects/dotfiles/zsh/plugins.sh

# Oh My Zsh Initialization
source ~/.oh-my-zsh/oh-my-zsh.sh

# -----------------------------------------------------------------------------
# FZF Integration (currently disabled)
# -----------------------------------------------------------------------------
# Uncomment to enable fuzzy finder integration
# Must be loaded AFTER compinit (oh-my-zsh) but BEFORE other completion plugins
# source ~/projects/dotfiles/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
# source ~/projects/dotfiles/zsh/fzf-tab-config.sh
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# source ~/projects/dotfiles/zsh/fzf.sh

# -----------------------------------------------------------------------------
# Custom Completion Configuration
# -----------------------------------------------------------------------------
# Load AFTER oh-my-zsh called compinit
# This file only configures completion behavior (menu selection, caching, etc.)
# It does NOT initialize the completion system
source ~/projects/dotfiles/zsh/completion.sh

source ~/projects/dotfiles/zsh/aliases.sh
source ~/projects/dotfiles/zsh/history_settings.sh

# Syntax Highlighting & Autosuggestions
# Load syntax highlighting and autosuggestions from Homebrew
if [[ $(uname -m) == 'arm64' ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Load p10k theme
source ~/projects/dotfiles/zsh/p10k.zsh

# Source OpenAI API key from config
if [ -f ~/.config/openai_key.sh ]; then
    source ~/.config/openai_key.sh
else
    echo "\033[31mError: OpenAI API key file not found at ~/.config/openai_key\033[0m"
fi

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# broot (tree navigator) launcher
# source /Users/servitola/.config/broot/launcher/bash/br
