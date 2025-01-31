#!/bin/zsh
sudo -v

source ~/projects/dotfiles/zsh/functions.sh
source ~/projects/dotfiles/zsh/aliases.sh

# echo "Updating XCode tools"
# sudo softwareupdate -i -a
# command -v xcode-select >/dev/null 2>&1 || xcode-select --install

echo "Updating all from Homebrew"
rm -rf "brew --cache"
brew tap --repair
brew cu --all --yes --quiet --no-quarantine
brew update
brew upgrade
mas upgrade
brew cleanup
brew doctor
brew bundle dump --force --file=~/projects/dotfiles/homebrew/.brewfile

echo "Update dotnet tools"
dotnet tool update -g dotnet-trace

echo "Flashing DNS cache"
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "Cleaning caches"
setopt rm_star_silent #turn off safe mode
rm -rfv ~/Library/Caches/*
rm -rfv /Library/Caches/*
echo "Clearing Logs from ~/Library/Logs"
find ~/Library/Logs -type f -name '*.log' -ls -delete
find ~/Library/Logs -type f -name '*.log.0' -ls -delete
rm -rfv ~/Library/Developer/Xcode/DerivedData/*
rm -rfv /private/var/folders/2t/mn_kwhnx7nz18bnw0mwh3qmm0000gn/T/xdb/logs/*
rm -rfv ~/.local/share/NuGet/v3-cache/*
echo "Cleaning .DS_Store files"
find . -type f -name '*.DS_Store' -ls -delete
echo "Cleaning Trash Bin"
rm -rfv /Volumes/*/.Trashes
rm -rfv ~/.Trash
rm -rfv /private/var/log/asl/*.asl
rm -rfv /Volumes/*/.Trashes; \
rm -rfv ~/.Trash/*; \

gameScreenshotsFolder="/Users/servitola/Library/Application Support/Blizzard/Heroes of the Storm/Screenshots"
[ -d "$gameScreenshotsFolder" ] && rm -- "$gameScreenshotsFolder"/*

setopt no_rm_star_silent #turn on safe mode back

echo "Updating tldr caches"
tldr --update

echo "checking android sdk licenses"
sdkmanager --licenses --verbose

reload

echo "Updating OhMyZsh"
zsh -ic "omz update"
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

purge

reload
