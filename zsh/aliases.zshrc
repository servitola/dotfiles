hash -d ct=~/projects/cTraderDev
hash -d d=~/Desktop
hash -d n=~/Downloads

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias -- -="cd -"

alias mkdir='mkdir -p'

alias d=~d
alias go_to_downloads=d
alias g="git"
alias n=cd ~n
alias ct=cd ~ct
alias l="ls -lF ${colorflag}"
# Always use color output for `ls`
alias ls="command ls ${colorflag}"
# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias python=python3
alias up='
sudo -v
sudo softwareupdate -i -a;
brew update; 
brew upgrade; 
brew cu --all; 
mas upgrade; 
brew cleanup; 
brew doctor; 
omz update; 
tldr --update;'
alias upgrade_all=up

alias re=". ~/.zshrc && echo 'ZSH config reloaded from ~/.zshrc'"
alias reload=re

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
alias path='echo -e ${PATH//:/\\n}'

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

alias mkdir='mkdir -p'
alias mkidr='mkdir -p'