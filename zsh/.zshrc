source ~/initialization.zshrc

ZSH_THEME="powerlevel10k/powerlevel10k"
eval $(thefuck --alias)
export UPDATE_ZSH_DAYS=7
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd-mm-yyyy"

source $ZSH/oh-my-zsh.sh
source ~/plugins.zshrc
source ~/aliases.zshrc
export PATH="/usr/local/sbin:$PATH"
source ~/history_settings.zshrc
source ~/.p10k.zsh
