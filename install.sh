#!/bin/zsh
H1='\033[0;31m===>'
H1_END='\033[0m'

sudo -v

echo "${H1} setting macos defaults ${H1_END}"
sh "./macos/set-defaults.sh"
sh "./macos/dock_setup.sh"

echo "${H1} installing XCode if needed ${H1_END}"
softwareupdate -i -a
command -v xcode-select >/dev/null 2>&1 || xcode-select --install

echo "${H1} installing homebrew if needed ${H1_END}"
command -v brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "${H1} installing brew packages listed in homebrew/.brewfile ${H1_END}"
brew bundle --file=homebrew/.brewfile --verbose

echo "${H1} setup git symlinks ${H1_END}"
rm -rf ~/.gitconfig
ln -s ~/projects/dotfiles/git/gitconfig ~/.gitconfig

echo "${H1} setup karabiner symlinks ${H1_END}"
rm -rf ~/.config/karabiner
ln -s ~/projects/dotfiles/karabiner ~/.config/karabiner

echo "${H1} setup goku symlinks ${H1_END}"
rm -rf ~/.config/karabiner.edn
ln -s ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

echo "${H1} setup hammerspoon symlinks ${H1_END}"
rm -rf ~/.hammerspoon
ln -s ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo "${H1} setup Visual Studio Code symlinks ${H1_END}"
rm -rf ~/Library/Application\ Support/Code/User
ln -s ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

echo "${H1} Setup zsh and terminal stuff symlinks ${H1_END}"
rm -rf ~/.zshrc
ln -s ~/projects/dotfiles/zsh/zshrc.zsh ~/.zshrc

echo "${H1} reload terminal ${H1_END}"
source ~/.zshrc

echo "${H1} installing oh-my-zsh to terminal if needed ${H1_END}"
[[ -d ~/.oh-my-zsh ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "${H1} installing powerlevel10k theme to terminal if needed ${H1_END}"
[[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "${H1} cloning nx-completion plugin to oh-my-zsh plugins ${H1_END}"
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo "${H1} cloning OhMyZsh-full-autoupdate to oh-my-zsh plugins ${H1_END}"
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate

echo "${H1} running usual update all script ${H1_END}"
sh "./macos/update-all-and-cleanup-all.sh"

echo "${H1} setup flameshot symlinks ${H1_END}"
rm -rf ~/.config/flameshot
ln -s ~/projects/dotfiles/flameshot ~/.config/flameshot

echo "${H1} Install Lulu from downloaded package ${H1_END}"
echo "${H1} Lulu forgets the settings when updated from homebrew ${H1_END}"
wget https://github.com/objective-see/LuLu/releases/download/v2.4.2/LuLu_2.4.2.dmg
open LuLu_2.4.2.dmg

echo "${H1} Install DockUtil since homebrew has version 2 still ${H1_END}"
wget https://github.com/kcrawford/dockutil/releases/download/3.0.2/dockutil-3.0.2.pkg
open dockutil-3.0.2.pkg

echo "${H1} Set default applications for different file extensions ${H1_END}"
sh "./macos/set_default_apps.sh"

echo "${H1} Check extra links for installation ${H1_END}"
echo "${H1} https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac ${H1_END}"
open https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac
