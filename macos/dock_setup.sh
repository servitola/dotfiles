#!/bin/zsh
dockutil --no-restart --remove all

dockApps=(
  "/Applications/LaunchPad.app"
 )

for i in "${dockApps[@]}"
do
  dockutil --no-restart --add $i
done

# dockutil --add '' --type spacer --section apps --after Finder
# dockutil --no-restart --add '~/Downloads' --view grid --display folder --sort dateadded

killall Dock
