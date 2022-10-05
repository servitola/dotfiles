#!/bin/zsh

source "zsh/functions.sh"
source "zsh/exports.sh"
source "macos/set_defaults.sh"
source "xcode/install.sh"
source "homebrew/install.sh"
source "homebrew/install_all_homebrew_packages.sh"
source "zsh/setup_zsh.sh"

echo "setup hosts file (perhaps you need to do it manually later)"
rm -rf /etc/hosts
ln -sfvh ~/projects/dotfiles/macos/hosts /etc/hosts

echo "setup git symlinks"
rm -rf ~/.gitconfig
ln -sfvh ~/projects/dotfiles/git/gitconfig ~/.gitconfig

echo "setup karabiner symlinks"
rm -rf ~/.config/karabiner
ln -sfvh ~/projects/dotfiles/karabiner ~/.config/karabiner

echo "setup goku symlinks"
rm -rf ~/.config/karabiner.edn
ln -sfvh ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

echo "setup hammerspoon symlinks"
rm -rf ~/.hammerspoon
ln -sfvh ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo "setup Visual Studio Code symlinks"
rm -rf ~/Library/Application\ Support/Code/User
ln -sfvh ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

echo "setup midnight commander symlink"
rm -rf ~/.config/mc
ln -sfvh ~/projects/dotfiles/midnight\ commander ~/.config/mc

echo "setup flameshot symlinks"
rm -rf ~/.config/flameshot
ln -sfvh ~/projects/dotfiles/flameshot ~/.config/flameshot

echo "install Lulu from downloaded package"
echo "Lulu forgets the settings when updated from homebrew"
curl -O https://github.com/objective-see/LuLu/releases/download/v2.4.2/LuLu_2.4.2.dmg
open LuLu_2.4.2.dmg

echo "install DockUtil since homebrew has version 2 still"
curl -O https://github.com/kcrawford/dockutil/releases/download/3.0.2/dockutil-3.0.2.pkg
open dockutil-3.0.2.pkg

echo "install Birman's keyboard Layout"
curl -O https://ilyabirman.ru/typography-layout/download/ilya-birman-typolayout-3.8-mac.dmg
open ilya-birman-typolayout-3.8-mac.dmg

echo "set default applications for different file extensions"
source "macos/set_default_apps.sh"

echo "check extra links for installation"
echo "https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac"
open https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac

echo "https://www.mrfdev.com/enhancer-for-youtube"
open https://www.mrfdev.com/enhancer-for-youtube

echo "run dock setup. Run once again when dockutil is installed please!"
source "macos/dock_setup.sh"

echo "installing trash-cli to replace rm with trash"
npm install --global trash-cli

echo "installing nanorc"
curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

mkd /usr/local/Cellar/node/node_global
npm config set prefix '/usr/local/Cellar/node/node_global'
