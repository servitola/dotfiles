#!/usr/bin/env bash
echo 'installing'

echo 'installing oh-my-zsh'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

brew bundle dump --force --file='~/projects/pc-scripts/homebrew/.brewfile'
sudo -v
#ln -s "~/projects/pc-scripts/visual studio code/" "/Users/servitola/Library/Application Support/Code/User"

git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion
ln -s ~/projects/pc-scripts/zsh/zshrc ~/.zshrc
ln -s ~/projects/pc-scripts/git/gitconfig ~/.gitconfig
sh "./mac setup scripts/set-defaults.sh"
sh "./homebrew/install_homebrew.sh"