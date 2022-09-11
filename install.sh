#!/usr/bin/env
H1='\033[0;31m===>'
H1_END='\033[0m'

sudo -v

echo "${H1} Check extra links for installation ${H1_END}"
echo "${H1} https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac ${H1_END}"
open https://ioshacker.com/how-to/use-touch-id-for-sudo-in-terminal-on-mac

echo "${H1} setting macos defaults ${H1_END}"
sh "./macos/set-defaults.sh"

echo "${H1} installing XCode if exists ${H1_END}"
softwareupdate -i -a
command -v xcode-select >/dev/null 2>&1 || xcode-select --install

echo "${H1} installing homebrew if exists ${H1_END}"
command -v brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "${H1} installing brew packages from file ${H1_END}"
brew bundle --file=homebrew/.brewfile --verbose

echo "${H1} setup git ${H1_END}"
rm -rf ~/.gitconfig
ln -s ~/projects/dotfiles/git/gitconfig ~/.gitconfig

echo "${H1} setup karabiner ${H1_END}"
rm -rf ~/.config/karabiner
ln -s ~/projects/dotfiles/karabiner ~/.config/karabiner

echo "${H1} setup goku ${H1_END}"
rm -rf ~/.config/karabiner.edn
ln -s ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

echo "${H1} setup hammerspoon ${H1_END}"
rm -rf ~/.hammerspoon
ln -s ~/projects/dotfiles/hammerspoon ~/.hammerspoon

echo "${H1} Visual Studio Code ${H1_END}"
rm -rf ~/Library/Application\ Support/Code/User
ln -s ~/projects/dotfiles/vscode/User ~/Library/Application\ Support/Code/User

echo "${H1} setup zsh ${H1_END}"
rm -rf ~/.zshrc
ln -s ~/projects/dotfiles/zsh/zshrc.zsh ~/.zshrc

echo "${H1} reload terminal ${H1_END}"
source ~/.zshrc

echo "${H1} installing oh-my-zsh ${H1_END}"
[[ -d ~/.oh-my-zsh ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "${H1} installing OhMyZsh-full-autoupdate.git ${H1_END}"
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate

echo "${H1} installing nx-completion ${H1_END}"
git clone https://github.com/jscutlery/nx-completion.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nx-completion

echo "${H1} running update all script ${H1_END}"
sh "./macos/update-all-and-cleanup-all.sh"

echo "${H1} setup flameshot ${H1_END}"
rm -rf ~/.config/flameshot
ln -s ~/projects/dotfiles/flameshot ~/.config/flameshot

echo "${H1} Install Lulu ${H1_END}"
echo "${H1} Lulu forgets the settings when updated from homebrew ${H1_END}"
wget https://github.com/objective-see/LuLu/releases/download/v2.4.2/LuLu_2.4.2.dmg
open LuLu_2.4.2.dmg

echo "${H1} Set default applications ${H1_END}"
sh "./macos/set_default_apps.sh"

echo "${H1} Sync environment variables with root ${H1_END}"
cp ~/projects/dotfiles/macos/osx-env-sync.plist ~/Library/LaunchAgents/osx-env-sync.plist
chmod +x ~/projects/dotfiles/macos/osx-env-sync.sh
launchctl unload ~/Library/LaunchAgents/osx-env-sync.plist
launchctl load ~/Library/LaunchAgents/osx-env-sync.plist
sh ./macos/osx-env-sync.sh