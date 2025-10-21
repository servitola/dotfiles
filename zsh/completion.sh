# =============================================================================
# Zsh Completion Configuration
# =============================================================================

# Load the zsh/complist module for advanced menu selection features
zmodload zsh/complist

# Start menu selection immediately (no need to press TAB multiple times)
zstyle ':completion:*' menu select=0

# Enable visual menu selection with arrow key navigation
zstyle ':completion:*' menu select

# Don't insert tab character if there's nothing to complete
zstyle ':completion:*' insert-tab false

# Complete special directories like . and ..
zstyle ':completion:*' special-dirs true

# Allow immediate arrow key navigation in completion menu
# This makes completion feel more responsive and intuitive
bindkey -M menuselect '^[[A' up-line-or-history      # Up arrow
bindkey -M menuselect '^[[B' down-line-or-history    # Down arrow
bindkey -M menuselect '^[[C' forward-char            # Right arrow
bindkey -M menuselect '^[[D' backward-char           # Left arrow

# Make completions case-insensitive
zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# -----------------------------------------------------------------------------
# Performance Optimizations
# -----------------------------------------------------------------------------
# Accept exact matches even if there are ambiguous matches
# This speeds up completion when you know exactly what you want
zstyle ':completion:*' accept-exact '*(N)'

# Enable completion caching for faster subsequent completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/.zcompcache"

# -----------------------------------------------------------------------------
# Directory Navigation Enhancements
# -----------------------------------------------------------------------------
# Automatically push directories onto the directory stack
setopt AUTO_PUSHD

# Don't push duplicate directories onto the stack
setopt PUSHD_IGNORE_DUPS

# Don't print directory stack after pushd/popd
setopt PUSHD_SILENT

# -----------------------------------------------------------------------------
# History Configuration
# -----------------------------------------------------------------------------
# Keep 10,000 lines of command history
HISTSIZE=10000
SAVEHIST=10000

# Remove duplicate commands from history
setopt HIST_IGNORE_ALL_DUPS

# Don't save duplicate commands
setopt HIST_SAVE_NO_DUPS

# Remove unnecessary whitespace from commands before saving
setopt HIST_REDUCE_BLANKS

# Append to history immediately (not when shell exits)
setopt INC_APPEND_HISTORY

# Save timestamps and durations in history
setopt EXTENDED_HISTORY

# -----------------------------------------------------------------------------
# Tab Key Behavior
# -----------------------------------------------------------------------------
# Make TAB key cycle through completions immediately (like Bash)
# Default zsh behavior requires TAB TAB to start cycling
# This makes it more intuitive for users coming from other shells
bindkey -M emacs '^I' menu-complete              # TAB cycles forward
bindkey -M viins '^I' menu-complete              # TAB cycles forward (vi mode)
bindkey -M emacs '^[[Z' reverse-menu-complete    # Shift-TAB cycles backward
bindkey -M viins '^[[Z' reverse-menu-complete    # Shift-TAB cycles backward (vi mode)
