#!/bin/zsh

source "zsh/functions.sh"
source "zsh/exports.sh"
source "macos/set_defaults.sh"
source "xcode/install.sh"
source "homebrew/install.sh"
source "homebrew/install_minimum_homebrew_packages.sh"
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
open /Applications/Hammerspoon.app

echo "setup Visual Studio Code symlinks"
rm -rf ~/Library/Application\ Support/Code/User
ln -sfvh ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

echo "setup midnight commander symlink"
rm -rf ~/.config/mc
ln -sfvh ~/projects/dotfiles/midnight\ commander ~/.config/mc

echo "setup windsurf main prompt symlink"
rm -rf ~/.windsurfrules
ln -sfvh ~/projects/dotfiles/windsurf/.windsurfrules ~/.windsurfrules
ln -sfvh ~/projects/dotfiles/windsurf/.windsurfrules ~/ai2_workspace/.windsurfrules

echo "setup flameshot symlinks"
rm -rf ~/.config/flameshot
ln -sfvh ~/projects/dotfiles/flameshot ~/.config/flameshot

echo "setup Rider vmoptions symlink"
rm -rf ~/Library/Application\ Support/JetBrains/Rider2024.3/rider.vmoptions
ln -sfvh ~/projects/dotfiles/jetbrains\ rider/rider.vmoptions ~/Library/Application\ Support/JetBrains/Rider2024.3/rider.vmoptions

echo "set default applications for different file extensions"
source "macos/set_default_apps.sh"

echo "run dock setup. Run once again when dockutil is installed please!"
source "macos/dock_setup.sh"

echo "installing trash-cli to replace rm with trash"
npm install --global trash-cli

echo "installing vsce to publish vscode extensions"
npm install --global vsce
npm install --global typescript

echo "installing nanorc"
mkdir -p ~/.nano/syntax
cd ~/.nano
curl -O https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
chmod +x install.sh
./install.sh
cd -

echo "installing Finder Context Menu"
rm -rf ~/Library/Group\ Containers/85P8ZUTQL8.net.langui.ContextMenu/Actions
ln -sfvh ~/projects/dotfiles/contextmenu/Actions ~/Library/Group\ Containers/85P8ZUTQL8.net.langui.ContextMenu/Actions
scripts_dir=~/Library/Application\ Scripts/net.langui.ContextMenuHelper
mkdir -p "$scripts_dir"
script_content=$'#!/bin/sh\npkill -nf ScriptMonitor\nexec "$@"'
helper_path="$scripts_dir/contextmenu.sh"
echo "$script_content" > "$helper_path"
chmod +x "$helper_path"
