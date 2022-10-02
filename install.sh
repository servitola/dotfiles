#!/bin/zsh
source zsh/functions.zsh

echo "setting macos defaults"
sh "./macos/set_defaults.sh"

echo "setup hosts file (perhaps you need to do it manually later)"
ln -sfvh ~/projects/dotfiles/macos/hosts /etc/hosts

echo "installing XCode if needed"
if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? 'Install XCode Command Line Tools'

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Point the `xcode-select` developer directory to
    # the appropriate directory from within `Xcode.app`
    # https://github.com/alrra/dotfiles/issues/13

    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
    print_result $? 'Make "xcode-select" developer directory point to Xcode'

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'

fi

echo "installing homebrew if needed"
command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "installing brew packages listed in homebrew/.brewfile"
brew bundle --file=homebrew/.brewfile --verbose

echo Make ZSH the default shell environment
chsh -s $(which zsh)
echo "Setup zsh and terminal stuff symlinks"
ln -sfvh ~/projects/dotfiles/zsh/zshrc.zsh ~/.zshrc

echo "setup git symlinks"
ln -sfvh ~/projects/dotfiles/git/gitconfig ~/.gitconfig

echo "setup karabiner symlinks"
ln -sfvh ~/projects/dotfiles/karabiner ~/.config/karabiner

echo "setup goku symlinks"
ln -sfvh ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

echo "setup hammerspoon symlinks"
ln -sfvh ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo "setup Visual Studio Code symlinks"
ln -sfvh ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

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
ln -sfvh ~/projects/dotfiles/midnight\ commander ~/.config/mc

echo "running usual update all script"
sh "./macos/update_all_and_cleanup_all.sh"

echo "setup flameshot symlinks"
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
sh "./macos/set_default_apps.sh"

echo "check extra links for installation"
echo "https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac"
open https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac

echo "run dock setup. Run once again when dockutil is installed please!"
sh "./macos/dock_setup.sh"

npm install --global trash-cli
curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
