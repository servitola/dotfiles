#!/bin/zsh
sudo -v

source macos/bash_helper_functions.sh
source ~/projects/dotfiles/zsh/aliases.zsh

echo "Updating XCode tools"
sudo softwareupdate -i -a
command -v xcode-select >/dev/null 2>&1 || xcode-select --install

echo "Updating all from Homebrew"
rm -rf "brew --cache"
brew tap --repair
brew cu --all --yes --quiet --no-quarantine
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "Updating OhMyZsh"
zsh -ic "omz update"
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

echo "Configure NPM"
npm config set fund false --location=global
npm install npm -g
npm update -g

echo "Flashing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "Cleaning caches"
setopt rm_star_silent #turn off safe mode
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "Cleaning DS_Store"
find . -type f -name '*.DS_Store' -ls -delete
echo "Cleaning Trash Bin"
rm -rfv /Volumes/*/.Trashes
rm -rfv ~/.Trash
rm -rfv /private/var/log/asl/*.asl
setopt no_rm_star_silent #turn on safe mode back

echo "Updating tldr caches"
tldr --update

reload
