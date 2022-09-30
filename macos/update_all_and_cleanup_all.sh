#!/bin/zsh
H1='\033[0;31m==>'
H1_END='\033[0m'

sudo -v

source ~/projects/dotfiles/zsh/aliases.zsh

echo "${H1} Updating XCode tools ${H1_END}"
sudo softwareupdate -i -a
command -v xcode-select >/dev/null 2>&1 || xcode-select --install

echo "${H1} Updating all from Homebrew ${H1_END}"
rm -rf "brew --cache"
brew tap --repair
brew cu --all --yes --quiet --no-quarantine
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "${H1} Updating OhMyZsh ${H1_END}"
zsh -ic "omz update"
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

echo "${H1} Configure NPM ${H1_END}"
npm config set fund false --location=global
npm install npm -g
npm update -g

echo "${H1} Flashing DNS cache ${H1_END}"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "${H1} Cleaning caches ${H1_END}"
setopt rm_star_silent #turn off safe mode
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "${H1} Cleaning DS_Store ${H1_END}"
find . -type f -name '*.DS_Store' -ls -delete
echo "${H1} Cleaning Trash Bin ${H1_END}"
rm -rfv /Volumes/*/.Trashes
rm -rfv ~/.Trash
rm -rfv /private/var/log/asl/*.asl
setopt no_rm_star_silent #turn on safe mode back

echo "${H1} Updating tldr caches ${H1_END}"
tldr --update

reload
