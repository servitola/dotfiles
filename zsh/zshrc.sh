# init powerlevel10k theme with its Instant Prompt feature
ZSH_THEME="powerlevel10k/powerlevel10k"

# set homebrew autoupdate each 24 hours
export HOMEBREW_AUTO_UPDATE_SECS="86400"
export HOMEBREW_NO_ENV_HINTS=1

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.shrc" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.shrc"
fi

# Initialize zoxide (smart directory jumper)
eval "$(zoxide init zsh)"

# Load completion system
autoload -Uz compinit && compinit

# Load fzf-tab (must be loaded after compinit but before other completion plugins)
source ~/projects/dotfiles/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source ~/projects/dotfiles/zsh/fzf-tab-config.sh

# Load fzf integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source ~/projects/dotfiles/zsh/fzf.sh

# Load better completion and navigation
source ~/projects/dotfiles/zsh/completion.sh

source ~/projects/dotfiles/zsh/exports.sh
source ~/projects/dotfiles/zsh/plugins.sh
source ~/.oh-my-zsh/oh-my-zsh.sh

source ~/projects/dotfiles/zsh/aliases.sh
source ~/projects/dotfiles/zsh/history_settings.sh
source ~/projects/dotfiles/zsh/p10k.zsh

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

# Source OpenAI API key from config
if [ -f ~/.config/openai_key ]; then
    source ~/.config/openai_key
else
    echo "\033[31mError: OpenAI API key file not found at ~/.config/openai_key\033[0m"
fi
