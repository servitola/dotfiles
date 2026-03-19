# =============================================================================
# Zsh Completion Configuration
# Loaded AFTER oh-my-zsh calls compinit
# =============================================================================

# Load the zsh/complist module for advanced menu selection features
zmodload zsh/complist

# Enable visual menu selection with arrow key navigation
zstyle ':completion:*' menu select

# Don't insert tab character if there's nothing to complete
zstyle ':completion:*' insert-tab false

# Complete special directories like . and ..
zstyle ':completion:*' special-dirs true

# Allow immediate arrow key navigation in completion menu
bindkey -M menuselect '^[[A' up-line-or-history      # Up arrow
bindkey -M menuselect '^[[B' down-line-or-history    # Down arrow
bindkey -M menuselect '^[[C' forward-char            # Right arrow
bindkey -M menuselect '^[[D' backward-char           # Left arrow

# Make completions case-insensitive
zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Accept exact matches even if there are ambiguous matches
zstyle ':completion:*' accept-exact '*(N)'

# Enable completion caching for faster subsequent completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/.zcompcache"

# TAB cycles through completions immediately (like Bash)
bindkey -M emacs '^I' menu-complete              # TAB cycles forward
bindkey -M viins '^I' menu-complete              # TAB cycles forward (vi mode)
bindkey -M emacs '^[[Z' reverse-menu-complete    # Shift-TAB cycles backward
bindkey -M viins '^[[Z' reverse-menu-complete    # Shift-TAB cycles backward (vi mode)

# Directory navigation
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
