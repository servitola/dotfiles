# BASH FIX
export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="/Users/servitola/.oh-my-zsh"

ZSH_THEME="powerlevel9k/powerlevel9k"

eval $(thefuck --alias)

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

export UPDATE_ZSH_DAYS=7

COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

HIST_STAMPS="dd-mm-yyyy"

source $ZSH/oh-my-zsh.sh

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

export EDITOR='nano'

alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias python=python3
alias brewup='brew update; brew upgrade; brew cleanup; brew doctor; omz update; tldr --update'
hash -d ct=~/projects/cTraderDev

plugins=(
  git
  bundler
  dotenv
  osx
  rake
  rbenv
  adb
  brew
  cask
  common-aliases
  npm
  pip
  python
  zsh-autosuggestions
)

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir rbenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%f"

local user_symbol="$"
if [[ $(print -P "%#") =~ "#" ]]; then
    user_symbol = "#"
fi

POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%{%B%F{black}%K{yellow}%} $user_symbol%{%b%f%k%F{yellow}%} %{%f%}"
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=’red’

if [ -f ~/.aliases ]; then
        . ~/.aliases
fi

export PATH="/usr/local/sbin:$PATH"
