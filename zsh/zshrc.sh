# init powerlevel10k theme with its Instant Prompt feature
ZSH_THEME="powerlevel10k/powerlevel10k"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.shrc" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.shrc"
fi

source ~/projects/dotfiles/zsh/exports.sh
source ~/projects/dotfiles/zsh/plugins.sh
source ~/.oh-my-zsh/oh-my-zsh.sh

source ~/projects/dotfiles/zsh/aliases.sh
source ~/projects/dotfiles/zsh/history_settings.sh
source ~/projects/dotfiles/zsh/p10k.sh

if [[ $(uname -m) == 'arm64' ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# source ~/projects/dotfiles/zsh/functions.sh
# initialize zsh-navigation-tools
# autoload znt-history-widget
# zle -N znt-history-widget
# bindkey "^H" znt-history-widget
# zle -N znt-cd-widget
# bindkey "^B" znt-cd-widget
# zle -N znt-kill-widget
# bindkey "^Y" znt-kill-widget
