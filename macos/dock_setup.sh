#!/bin/zsh

# The purpose of this component
# is to build the Dock, one app at a time.
# Dock preferences are located in components/osx/preferences/Dock

echo_title_update "Dock"

dockutil --no-restart --remove all

dockApps=(

  )

for i in "${dockApps[@]}"
do
  dockutil --no-restart --add $i
done

dockutil --add '' --type spacer --section apps --after Spotify
dockutil --add '' --type spacer --section apps --after Safari
dockutil --add '' --type spacer --section apps --after Franz

dockutil --no-restart --add "~/Downloads" --view list --display folder --sort dateadded

killall Dock