#!/usr/bin/env bash
sudo -v

echo 'Check extra links for installation'
echo 'https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac'

echo 'setting macos defaults'
sh "./macos/set-defaults.sh"

echo 'installing XCode'
xcode-select --install

echo 'installing homebrew'
command -v brew >/dev/null 2>&1 || { echo >&2 "Installing Homebrew Now"; \
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; }

echo 'installing brew packages from file'
brew bundle --file=homebrew/.brewfile --verbose

echo 'installing git'
rm -rf ~/.gitconfig
ln -s ~/projects/dotfiles/git/.gitconfig ~/.gitconfig

echo 'installing karabiner CHECK'
rm -rf ~/.config/karabiner
ln -s ~/projects/dotfiles/karabiner ~/.config/karabiner

echo 'run goku'
goku

echo 'installing hammerspoon CHECK'
rm -rf ~/.hammerspoon
ln -s ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo 'Visual Studio Code'
rm -rf ~/Library/Application\ Support/Code/User
ln -s ~/projects/dotfiles/visual\ studio\ code/User ~/Library/Application\ Support/Code/User

echo 'installing zsh'
rm -rf ~/.zshrc
ln -s ~/projects/dotfiles/zsh/.zsh ~/.zshrc

echo 'reload terminal'
source ~/.zsh

echo 'installing oh-my-zsh'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo 'installing OhMyZsh-full-autoupdate.git'
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate

echo 'installing nx-completion'
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo 'running update all script'
/bin/bash "./macos/update-all-and-cleanup-all.sh"