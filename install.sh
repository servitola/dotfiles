#!/bin/zsh
source macos/bash_helper_functions.sh

sudo -v

echo "setting macos defaults"
sh "./macos/set_defaults.sh"

echo "setup hosts file (perhaps you need to do it manually later)"
ln -sfv ~/projects/dotfiles/macos/hosts /etc/hosts

echo "installing XCode if needed"
softwareupdate -i -a
command -v xcode-select >/dev/null 2>&1 || xcode-select --install

echo "installing homebrew if needed"
command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "installing brew packages listed in homebrew/.brewfile"
brew bundle --file=homebrew/.brewfile --verbose

echo "install fzf"
/usr/local/opt/fzf/install

echo "setup git symlinks"
ln -sfv ~/projects/dotfiles/git/gitconfig ~/.gitconfig

echo "setup karabiner symlinks"
ln -sfv ~/projects/dotfiles/karabiner ~/.config/karabiner

echo "setup goku symlinks"
ln -sfv ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

echo "setup hammerspoon symlinks"
ln -sfv ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo "setup Visual Studio Code symlinks"
ln -sfv ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

echo "Setup zsh and terminal stuff symlinks"
ln -sfv ~/projects/dotfiles/zsh/zshrc.zsh ~/.zshrc

echo "reload terminal"
source ~/.zshrc

echo "installing oh-my-zsh to terminal if needed"
[[ -d ~/.oh-my-zsh ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "installing powerlevel10k theme to terminal if needed"
[[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "cloning nx-completion plugin to oh-my-zsh plugins"
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo "cloning OhMyZsh-full-autoupdate to oh-my-zsh plugins"
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate

echo "setup midnight commander symlink"
ln -sfv ~/projects/dotfiles/midnight\ commander ~/.config/mc

echo "running usual update all script"
sh "./macos/update_all_and_cleanup_all.sh"

echo "setup flameshot symlinks"
ln -sfv ~/projects/dotfiles/flameshot ~/.config/flameshot

echo "install Lulu from downloaded package"
echo "Lulu forgets the settings when updated from homebrew"
wget https://github.com/objective-see/LuLu/releases/download/v2.4.2/LuLu_2.4.2.dmg
open LuLu_2.4.2.dmg

echo "install DockUtil since homebrew has version 2 still"
wget https://github.com/kcrawford/dockutil/releases/download/3.0.2/dockutil-3.0.2.pkg
open dockutil-3.0.2.pkg

echo "install Birman's keyboard Layout"
wget https://ilyabirman.ru/typography-layout/download/ilya-birman-typolayout-3.8-mac.dmg
open ilya-birman-typolayout-3.8-mac.dmg

echo "set default applications for different file extensions"
sh "./macos/set_default_apps.sh"

echo "check extra links for installation"
echo "https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac"
open https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac

echo "run dock setup. Run once again when dockutil is installed please!"
sh "./macos/dock_setup.sh"
