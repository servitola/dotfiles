#!/usr/bin/env bash
sudo -v

echo "${bold}==> Updating XCode tools ${normal}"
sudo softwareupdate -i -a
xcode-select --install

echo "${bold}==> Updating all from Homebrew ${normal}"
rm -rf "brew --cache"
brew cu --all -y -q
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor 
omz update
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "${bold}==> Update tldr caches ${normal}"
tldr --update

npm config set fund false --global

echo "${bold}==> Flashing DNS cache ${normal}"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "${bold}==> Cleaning caches ${normal}"
setopt rm_star_silent
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/*
setopt no_rm_star_silent

reload