#!/bin/zsh

echo "installing brew packages listed in homebrew/.brewfile"
brew bundle --file=homebrew/.brewfile --verbose
