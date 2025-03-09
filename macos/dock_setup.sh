#!/bin/zsh
echo "Set Dock to the right"
defaults write com.apple.dock "orientation" -string "right"

echo "Dim hidden apps"
defaults write com.apple.dock showhidden -bool true

echo "Don’t automatically rearrange Spaces based on most recent use"
defaults write com.apple.dock mru-spaces -bool false

echo "Minimize windows into their application’s icon"
defaults write com.apple.dock minimize-to-application -bool true

echo "Don’t show recent applications in Dock"
defaults write com.apple.dock show-recents -bool false

echo "Visualize CPU usage in the Activity Monitor Dock icon"
defaults write com.apple.ActivityMonitor IconType -int 5

echo "Remove all Dock icons"
dockutil --no-restart --remove all

echo "Set LaunchPad to Dock"
dockApps=(
  "/Applications/LaunchPad.app"
)

for i in "${dockApps[@]}"
do
  dockutil --no-restart --add $i
done

killall Dock
