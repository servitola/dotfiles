#!/bin/zsh

echo "Make ZSH the default shell environment"
if [[ $SHELL != $(which zsh) ]]; then
    chsh -s $(which zsh)
fi

echo "Setup zsh and terminal stuff symlinks"
rm -rf ~/.zshrc
ln -sfvh ~/projects/dotfiles/zsh/zshrc.sh ~/.zshrc
rm -rf ~/.zprofile
ln -sfvh ~/projects/dotfiles/zsh/zprofile.sh ~/.zprofile

echo "Installing/updating oh-my-zsh if needed"
if [[ ! -d ~/.oh-my-zsh ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Installing/updating powerlevel10k theme if needed"
if [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo "Powerlevel10k already installed, updating..."
    cd ~/.oh-my-zsh/custom/themes/powerlevel10k && git pull
fi

echo "cloning nx-completion plugin to oh-my-zsh plugins"
[[ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion ]] || git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo "cloning OhMyZsh-full-autoupdate to oh-my-zsh plugins"
[[ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate ]] || git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
