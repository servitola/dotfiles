# init powerlevel10k theme with its Instant Prompt feature
ZSH_THEME="powerlevel10k/powerlevel10k"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zshrc" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zshrc"
fi

source ~/projects/dotfiles/zsh/exports.zsh
source ~/projects/dotfiles/zsh/plugins.zsh
source ~/.oh-my-zsh/oh-my-zsh.sh
source ~/projects/dotfiles/zsh/aliases.zsh
source ~/projects/dotfiles/zsh/history_settings.zsh
source ~/projects/dotfiles/zsh/p10k.zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# initialize zsh-navigation-tools
autoload znt-history-widget
zle -N znt-history-widget
bindkey "^H" znt-history-widget
zle -N znt-cd-widget
bindkey "^B" znt-cd-widget
zle -N znt-kill-widget
bindkey "^Y" znt-kill-widget

# initiliaze fzf - general-purpose command-line fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
