#!/usr/bin/env bash
sudo -v

echo "==> Updating XCode tools"
sudo softwareupdate -i -a
xcode-select --install

echo "==> Updating all from Homebrew"
rm -rf "brew --cache"
brew cu --all -y -q
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor 
omz update
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "==> Update tldr caches"
tldr --update

npm config set fund false --global

echo "==> Flashing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "==> Cleaning caches"
setopt rm_star_silent
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/*
setopt no_rm_star_silent

reload