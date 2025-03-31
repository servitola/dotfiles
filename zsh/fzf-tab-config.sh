# Preview directory content with exa/ls
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'

# Switch group using alt-, and alt-.
zstyle ':fzf-tab:*' switch-group 'alt-,' 'alt-.'

# Preview files with bat/cat
# zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:200 ${realpath} 2>/dev/null || cat ${realpath} 2>/dev/null || echo ${realpath} 2>/dev/null'

# Immediate completion with minimal preview
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --cycle --info=inline --no-mouse

# Disable previews completely for instant response
zstyle ':fzf-tab:*' fzf-preview ''

# Make completion immediate
zstyle ':fzf-tab:*' continuous-trigger ''
zstyle ':fzf-tab:*' accept-line enter
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' single-group color header

# Faster completion menu design
zstyle ':fzf-tab:*' default-color $'\033[37m'
zstyle ':fzf-tab:*' filled-color $'\033[34m'

# Show file type indicators without extra processing
zstyle ':fzf-tab:complete:*' suffix ''

# Use input as query string when completing path
zstyle ':fzf-tab:complete:*' query-string input

# Disable sort when completing options of any command
zstyle ':completion:complete:*:options' sort false

# Use fzf-tab for these commands
zstyle ':fzf-tab:complete:(cd|ls|eza|bat|cat|vim|nvim):*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null'

# Limit the number of items to display for faster response
zstyle ':fzf-tab:*' max-lines 15

# Make tab trigger immediate selection mode
zstyle ':fzf-tab:*' insert-space false
zstyle ':fzf-tab:*' show-group brief
