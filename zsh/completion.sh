# =============================================================================
# Zsh Completion Configuration
# =============================================================================
# This file ONLY configures completion behavior and keybindings.
# It does NOT initialize the completion system (compinit).
#
# Why? Because oh-my-zsh.sh already called compinit before this file loads.
# The initialization order is:
#   1. .zprofile     → Sets FPATH (includes Homebrew completions path)
#   2. oh-my-zsh.sh  → Calls compinit (discovers all completion functions)
#   3. This file     → Configures how completions behave
#
# If we called compinit here, we would:
#   - Initialize the completion system twice (slow)
#   - Override oh-my-zsh's configuration
#   - Potentially corrupt the completion cache
# =============================================================================

# -----------------------------------------------------------------------------
# Load Completion Modules
# -----------------------------------------------------------------------------
# Load the zsh/complist module for advanced menu selection features
zmodload zsh/complist

# -----------------------------------------------------------------------------
# Menu Selection Configuration
# -----------------------------------------------------------------------------
# Start menu selection immediately (no need to press TAB multiple times)
zstyle ':completion:*' menu select=0

# Enable visual menu selection with arrow key navigation
zstyle ':completion:*' menu select

# Don't insert tab character if there's nothing to complete
zstyle ':completion:*' insert-tab false

# Complete special directories like . and ..
zstyle ':completion:*' special-dirs true

# -----------------------------------------------------------------------------
# Completion Styling (Colors and Formatting)
# -----------------------------------------------------------------------------
# Use LS_COLORS for file completion coloring
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Group completions by category
zstyle ':completion:*' group-name ''

# Add descriptions to completion groups
zstyle ':completion:*:descriptions' format '%B%F{blue}— %d —%f%b'

# Add warning message when no completions found
zstyle ':completion:*:warnings' format '%B%F{red}No matches found%f%b'

# Add messages for corrections
zstyle ':completion:*:messages' format '%F{yellow}%d%f'

# Format for corrections (when you mistype)
zstyle ':completion:*:corrections' format '%B%F{yellow}— %d (errors: %e) —%f%b'

# Completion menu colors (when selecting with arrows)
# Uses terminfo capabilities for better compatibility
zstyle ':completion:*' menu select=1
zstyle ':completion:*' list-colors ''

# Show completion menu on successive tab press
zstyle ':completion:*' menu select=long

# Better completion for kill command (show process names)
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,comm'

# Better completion for cd command (show only directories)
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Completion for .. goes to parent directories
zstyle ':completion:*:*:cd:*' tag-order local-directories path-directories

# -----------------------------------------------------------------------------
# Menu Selection Keybindings
# -----------------------------------------------------------------------------
# Allow immediate arrow key navigation in completion menu
# This makes completion feel more responsive and intuitive
bindkey -M menuselect '^[[A' up-line-or-history      # Up arrow
bindkey -M menuselect '^[[B' down-line-or-history    # Down arrow
bindkey -M menuselect '^[[C' forward-char            # Right arrow
bindkey -M menuselect '^[[D' backward-char           # Left arrow

# Accept and continue to next completion with Space
bindkey -M menuselect ' ' accept-and-infer-next-history

# -----------------------------------------------------------------------------
# Case-Insensitive Completion
# -----------------------------------------------------------------------------
# Make completions case-insensitive
# Examples:
#   - 'cd doc' completes to 'Documents'
#   - 'cd DOC' completes to 'Documents'
#   - 'git che' completes to 'checkout'
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

# Limit completion list size for better performance
zstyle ':completion:*' list-max-items 100

# -----------------------------------------------------------------------------
# Directory Navigation Enhancements
# -----------------------------------------------------------------------------
# Automatically push directories onto the directory stack
setopt AUTO_PUSHD

# Don't push duplicate directories onto the stack
setopt PUSHD_IGNORE_DUPS

# Don't print directory stack after pushd/popd
setopt PUSHD_SILENT

# Auto-cd when typing just a directory name
setopt AUTO_CD

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

# Don't record commands starting with space
setopt HIST_IGNORE_SPACE

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
