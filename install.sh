#!/usr/bin/env bash
sudo -v

echo 'Do you use internal keyboard? (y/n)'
read installKarabiner

echo 'Check extra links for installation'
echo 'https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac'

echo 'setting macos defaults'
sh "./macos/set-defaults.sh"

echo 'installing XCode'
xcode-select --install

echo 'installing homebrew'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo 'installing brew packages from file CHECK'
brew bundle --file=homebrew/.brewfile --verbose

echo 'installing git'
rm -rf ~/.git
ln -s ~/projects/pc-scripts/git/.gitconfig ~/.gitconfig

if [ "$installKarabiner" != "${installKarabiner#[Yy]}" ] ;then
    echo 'installing karabiner CHECK'
    brew install --cask karabiner
    brew install --cask karabiner-elements
    rm -rf ~/.config/karabiner
    ln -s ~/projects/pc-scripts/karabiner ~/.config/karabiner
else
    echo 'No karabiner installed as decided'
fi

echo 'run goku'
goku

echo 'installing hammerspoon CHECK'
rm -rf ~/.hammerspoon
ln -s ~/projects/pc-scripts/hammerspoon ~/.hammerspoon

echo 'Visual Studio Code'
rm -rf ~/Library/Application\ Support/Code/User
ln -s ~/projects/dotfiles/visual\ studio\ code/User ~/Library/Application\ Support/Code/User

echo 'installing zsh'
rm -rf ~/.zshrc
ln -s ~/projects/pc-scripts/zsh/.zshrc ~/.zshrc

echo 'reload terminal'
source ~/.zshrc

echo 'installing oh-my-zsh'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo 'installing OhMyZsh-full-autoupdate.git'
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate

echo 'installing nx-completion'
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo 'running update all script'
sh "./macos/update-all.sh"