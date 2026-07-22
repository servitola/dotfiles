#!/bin/zsh

echo "installing brew packages listed in homebrew/minimum_brewfile"
brew bundle --file=~/projects/dotfiles/homebrew/minimum_brewfile --verbose
