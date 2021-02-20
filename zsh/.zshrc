source ~/initialization.zshrc

ZSH_THEME="powerlevel10k/powerlevel10k"
export UPDATE_ZSH_DAYS=7
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd-mm-yyyy"

# local user_symbol="$"
# if [[ $(print -P "%#") =~ "#" ]]; then
#     user_symbol = "#"
# fi

source ~/plugins.zshrc
source ~/aliases.zshrc
source ~/history_settings.zshrc
source ~/.p10k.zsh
