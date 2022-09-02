bold=$(tput bold)
normal=$(tput sgr0)

alias up='sh ~/projects/dotfiles/macos/update-all-and-cleanup-all.sh'

alias reload=". ~/.zshrc && echo 'ZSH config reloaded from ~/.zshrc'"

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias python=python3
alias pip=pip3

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
alias path_display='echo -e ${PATH//:/\\n}'

# Show/hide hidden files in Finder
alias show_hidden_files="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide_hidden_files="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# EXA aliases
alias ls='exa'                                                         # ls
alias l='exa -lbF --git'                                               # list, size, type, git
alias ll='exa -lbGF --git'                                             # long list
alias llm='exa -lbGF --git --sort=modified'                            # long list, modified date sort
alias la='exa -lbhHigUmuSa --time-style=long-iso --git --color-scale'  # all list
alias lx='exa -lbhHigUmuSa@ --time-style=long-iso --git --color-scale' # all + extended list
alias lS='exa -1'			                                                  # one column, just names
alias lt='exa --tree --level=2'
# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"