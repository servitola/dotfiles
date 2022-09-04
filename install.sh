#!/usr/bin/env bash
H1='\033[0;31m==>'
H1_END='\033[0m'

sudo -v

echo '${H1} Check extra links for installation ${/H1}'
echo '${H1} https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac ${/H1}'

echo '${H1} setting macos defaults ${H1_END}'
sh "./macos/set-defaults.sh"

echo '${H1} installing XCode ${H1_END}'
xcode-select --install

echo '${H1} installing homebrew ${H1_END}'
command -v brew >/dev/null 2>&1 || { echo >&2 "Installing Homebrew Now"; \
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; }

echo '${H1} installing brew packages from file ${H1_END}'
brew bundle --file=homebrew/.brewfile --verbose

echo '${H1} installing git ${H1_END}'
rm -rf ~/.gitconfig
ln -s ~/projects/dotfiles/git/.gitconfig ~/.gitconfig

echo '${H1} installing karabiner CHECK ${H1_END}'
rm -rf ~/.config/karabiner
ln -s ~/projects/dotfiles/karabiner ~/.config/karabiner

echo '${H1} install goku CHECK ${H1_END}'
rm -rf ~/.goku
ln -s ~/projects/dotfiles/goku ~/.goku

echo '${H1} installing hammerspoon CHECK ${H1_END}'
rm -rf ~/.hammerspoon
ln -s ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo '${H1} Visual Studio Code ${H1_END}'
rm -rf ~/Library/Application\ Support/Code/User
ln -s ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

echo '${H1} installing zsh ${H1_END}'
rm -rf ~/.zshrc
ln -s ~/projects/dotfiles/zsh/zshrc.zsh ~/.zshrc

echo '${H1} reload terminal ${H1_END}'
source ~/.zshrc

echo '${H1} installing oh-my-zsh ${H1_END}'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo '${H1} installing OhMyZsh-full-autoupdate.git ${H1_END}'
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate

echo '${H1} installing nx-completion ${H1_END}'
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo '${H1} running update all script ${H1_END}'
/bin/bash "./macos/update-all-and-cleanup-all.sh"

echo '${H1} Install Lulu ${H1_END}'
open https://objective-see.org/products/lulu.html

echo '${H1} Sync Environment Variables from bash level to MacOS level ${H1_END}'
echo '${H1} 1. Download the launch agent ${H1_END}'
curl https://raw.githubusercontent.com/ersiner/osx-env-sync/master/osx-env-sync.plist -o ~/Library/LaunchAgents/osx-env-sync.plist
echo '${H1} 2. Download the shell script ${H1_END}'
curl https://raw.githubusercontent.com/ersiner/osx-env-sync/master/osx-env-sync.sh -o ~/projects/dotfiles/macos/.osx-env-sync.sh