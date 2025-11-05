# Setup fzf with optimized settings
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 40% 
  --layout=reverse 
  --border 
  --info=inline
  --no-mouse
  --cycle
  --bind 'ctrl-a:select-all'
  --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
  --bind 'ctrl-e:execute(echo {+} | xargs -o $EDITOR)'
  --bind 'ctrl-v:execute(code {+})'
"

# Faster directory search
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'ls --color=always {}'"

# Faster file search
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'head -100 {}'"

# Better history search
function fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# cd with preview
function cdf() {
    local dir
    dir=$(fd --type d --strip-cwd-prefix --hidden --follow --exclude .git | fzf --preview 'ls --color=always {}') &&
        cd "$dir"
}

# Better file search
function ff() {
    local file
    file=$(fd --type f --strip-cwd-prefix --hidden --follow --exclude .git | fzf --preview 'head -100 {}') &&
        ${EDITOR:-vim} "$file"
}

# Enhanced zoxide with fzf
function zz() {
    local dir
    dir="$(zoxide query -l | fzf --preview 'ls --color=always {}')" &&
        cd "${dir}"
}

# Key bindings
bindkey '^R' fh  # Ctrl-R for history search
bindkey '^T' ff  # Ctrl-T for file search
bindkey '^G' cdf # Ctrl-G for directory search
bindkey '^Z' zz  # Ctrl-Z for zoxide + fzf
