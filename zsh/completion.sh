# Better completion system
autoload -Uz compinit && compinit

# Load required modules
zmodload zsh/complist

# Make completion immediate
zstyle ':completion:*' menu select=0

# Use menu selection with immediate navigation
zstyle ':completion:*' menu select
zstyle ':completion:*' insert-tab false
zstyle ':completion:*' special-dirs true

# Allow immediate arrow key navigation in menu
bindkey -M menuselect '^[[A' up-line-or-history
bindkey -M menuselect '^[[B' down-line-or-history
bindkey -M menuselect '^[[C' forward-char
bindkey -M menuselect '^[[D' backward-char

# Case insensitive path-completion 
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Faster completion
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/.zcompcache"

# Better directory stack navigation
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Better history navigation
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

# Make Tab key behavior more intuitive
bindkey -M emacs '^I' menu-complete
bindkey -M viins '^I' menu-complete
bindkey -M emacs '^[[Z' reverse-menu-complete
bindkey -M viins '^[[Z' reverse-menu-complete
