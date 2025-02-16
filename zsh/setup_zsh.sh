#!/bin/zsh

echo Make ZSH the default shell environment
chsh -s $(which zsh)
echo "Setup zsh and terminal stuff symlinks"
rm -rf ~/.zshrc
ln -sfvh ~/projects/dotfiles/zsh/zshrc.sh ~/.zshrc
rm -rf ~/.zprofile
ln -sfvh ~/projects/dotfiles/zsh/zprofile.sh ~/.zprofile

echo "installing oh-my-zsh to terminal if needed"
[[ -d ~/.oh-my-zsh ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "installing powerlevel10k theme to terminal if needed"
[[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "cloning nx-completion plugin to oh-my-zsh plugins"
[[ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion ]] || git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo "cloning OhMyZsh-full-autoupdate to oh-my-zsh plugins"
[[ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate ]] || git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
