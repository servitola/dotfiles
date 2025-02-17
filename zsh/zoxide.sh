# Enhanced zoxide configuration
export _ZO_ECHO=1  # Show directory before jumping
export _ZO_RESOLVE_SYMLINKS=1  # Better symlink handling
export _ZO_EXCLUDE_DIRS="$HOME:$HOME/Library:$HOME/.Trash:$HOME/Downloads"  # Exclude noisy directories
export _ZO_FZF_OPTS="
  --height 40%
  --reverse
  --border
  --cycle
  --info=inline
  --preview 'ls -l --color=always {2} 2>/dev/null || ls -l --color=always {}'
  --preview-window=right:50%:wrap
  --bind '?:toggle-preview'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --bind 'ctrl-y:execute-silent(echo {2} | pbcopy)'
  --color=fg:7,bg:-1,hl:6,fg+:15,bg+:-1,hl+:6
  --color=info:2,prompt:1,spinner:5,pointer:5,marker:3,header:4
"

# Quick aliases for faster navigation
alias j='z'       # Quick jump
alias ji='zi'     # Interactive selection
alias jb='z -b'   # Best match
alias jl='zoxide query -l | fzf --height 40% --preview "ls -l --color=always {}" | xargs -r z'  # List and select

# Enhanced jumping functions
function jp() {
    # Jump to parent directory matching pattern
    local dir
    dir=$(pwd | sed 's/[^/]/\//g' | sed 's/\//\.\.\//g' | xargs dirname | fzf --height 40% --preview "ls -l --color=always {}" --query "$1")
    [ -n "$dir" ] && z "$dir"
}

function jr() {
    # Jump to subdirectory recursively
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf --height 40% --preview "ls -l --color=always {}" --query "$1")
    [ -n "$dir" ] && z "$dir"
}
