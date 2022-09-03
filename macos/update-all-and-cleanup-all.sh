#!/usr/bin/env bash
RED='\033[0;31m'
NOCOLOR='\033[0m'

sudo -v

echo "${RED}==> Updating XCode tools${NOCOLOR}"
sudo softwareupdate -i -a
xcode-select --install

echo "${RED}==> Updating all from Homebrew${NOCOLOR}"
rm -rf "brew --cache"
brew cu --all -y -q
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor 
omz update
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "${RED}==> Update tldr caches${NOCOLOR}"
tldr --update

npm config set fund false --location=global

echo "${RED}==> Flashing DNS cache${NOCOLOR}"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "${RED}==> Cleaning caches${NOCOLOR}"
setopt rm_star_silent
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/*
setopt no_rm_star_silent

reload