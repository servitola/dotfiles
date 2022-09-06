if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zshrc" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zshrc"
fi

source ~/projects/dotfiles/zsh/initialization.zsh

ZSH_THEME="powerlevel10k/powerlevel10k"
eval $(thefuck --alias)
export UPDATE_ZSH_DAYS=7
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd-mm-yyyy"
ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh
source ~/projects/dotfiles/zsh/plugins.zsh
source ~/projects/dotfiles/zsh/aliases.zsh
source ~/projects/dotfiles/zsh/history_settings.zsh
source ~/projects/dotfiles/zsh/p10k.zsh

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir rbenv vcs) 
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%f"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%{%B%F{black}%K{yellow}%} $user_symbol%{%b%f%k%F{yellow}%} %{%f%}"
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=’red’

TOUCHBAR_GIT_ENABLED=true
GIT_UNCOMMITTED="+"
GIT_UNSTAGED="!"
GIT_UNTRACKED="?"
GIT_STASHED="$"
GIT_UNPULLED="⇣"
GIT_UNPUSHED="⇡"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
