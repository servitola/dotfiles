# =============================================================================
# .zshrc - Interactive Shell Configuration
# =============================================================================

# Powerlevel10k Instant Prompt
# Should stay close to the top of .zshrc for optimal performance
ZSH_THEME="powerlevel10k/powerlevel10k"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Async autosuggestions for better performance
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# -----------------------------------------------------------------------------
# Plugin Configuration (BEFORE oh-my-zsh loads)
# -----------------------------------------------------------------------------
# Define which oh-my-zsh plugins to load
source ~/projects/dotfiles/zsh/plugins.sh

# Oh My Zsh Initialization
source ~/.oh-my-zsh/oh-my-zsh.sh

# -----------------------------------------------------------------------------
# Custom Completion Configuration
# -----------------------------------------------------------------------------
# Load AFTER oh-my-zsh called compinit
# This file only configures completion behavior (menu selection, caching, etc.)
# It does NOT initialize the completion system
source ~/projects/dotfiles/zsh/completion.sh
source ~/projects/dotfiles/zsh/history_settings.sh
source ~/projects/dotfiles/zsh/functions.sh
source ~/projects/dotfiles/zsh/aliases.sh

# Load additional plugins from Homebrew
source ${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load p10k theme
source ~/projects/dotfiles/zsh/p10k.zsh

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Atuin shell history (--disable-up-arrow keeps native prefix search on up/down)
eval "$(atuin init zsh --disable-up-arrow)"

# Up/down arrow: prefix-based history search (type beginning, then arrow to filter)
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end  # Standard terminals
bindkey "^[OA" history-beginning-search-backward-end  # Application mode (iTerm2)
bindkey "^[[B" history-beginning-search-forward-end   # Down arrow standard
bindkey "^[OB" history-beginning-search-forward-end   # Down arrow application mode

source ~/.config/claude_code_settings.sh

# zoxide for fast directory navigation (must be last — hooks into precmd)
eval "$(zoxide init zsh)"
