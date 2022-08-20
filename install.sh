#!/usr/bin/env bash
echo 'installing'
brew bundle dump --force --file='~/projects/pc-scripts/homebrew/.brewfile'
ln -s ~/projects/pc-scripts/visual\ studio\ code/User ~/Library/Application\ Support/Code/User
ln -s ~/projects/pc-scripts/zsh/.zshrc ~/.zshrc
ln -s ~/projects/pc-scripts/git/gitconfig ~/.gitconfig
pause