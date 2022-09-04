#!/usr/bin/env zsh
H1='\033[0;31m==>'
H1_END='\033[0m'

sudo -v

echo "${H1} Updating XCode tools ${H1_END}"
sudo softwareupdate -i -a
xcode-select --install

echo "${H1} Updating all from Homebrew ${H1_END}"
rm -rf "brew --cache"
brew cu --all -y -q
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor 
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "${H1} Updating OhMyZsh ${H1_END}"
omz update

echo "${H1} Configure NPM ${H1_END}"
npm config set fund false --location=global

echo "${H1} Flashing DNS cache ${H1_END}"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "${H1} Cleaning caches ${H1_END}"
setopt rm_star_silent #turn off safe mode
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/*
setopt no_rm_star_silent #turn on safe mode back

echo "${H1} Updating tldr caches ${H1_END}"
tldr --update

reload