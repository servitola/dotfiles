#!/usr/bin/env bash

sudo -v

echo "Close any open System Preferences panes, to prevent them from overriding"
osascript -e 'tell application "System Preferences" to quit'

echo "Disable the sound effects on boot"
sudo nvram SystemAudioVolume=" "

echo "Disable Siri and remove the menu bar icon"
launchctl unload -w /System/Library/LaunchAgents/com.apple.Siri.plist 2> /dev/null
defaults write com.apple.Siri StatusMenuVisible -int 0
defaults write com.apple.Siri UserHasDeclinedEnable -int 1

echo "Disable the “Are you sure you want to open this application?” dialog"
sudo spctl --master-disable
defaults write com.apple.LaunchServices LSQuarantine -bool false

echo "Turn Off .dmg Verify"
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

echo "Save to disk (not to iCloud) by default"
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

echo "Add message to Login Windows"
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText  "Found this computer? Please contact me at: servitola@gmail.com"

echo "Set highlight color to green"
defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

echo "Disable the “Are you sure you want to open this application?” dialog"
defaults write com.apple.LaunchServices LSQuarantine -bool false

echo "Disable shadow in screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

echo "Always open everything in Finder's list view. This is important."
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

echo "Show the ~/Library folder."
chflags nohidden ~/Library

###############################################################################
echo "Finder"                                                                 #
###############################################################################

echo "Set the Finder prefs for showing a few different volumes on the Desktop."
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

defaults write com.apple.finder ShowTabView -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

echo "When performing a search, search the current folder by default"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

echo "Avoid creating .DS_Store files on network volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "Use list view in all Finder windows by default"
echo "Four-letter codes for the other view modes: 'icnv', 'clmv', 'Flwv'"
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

echo "Expand the following File Info panes:"
echo "'General', 'Open with', and 'Sharing & Permissions'"
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true

###############################################################################
echo "Activity Monitor"                                                       #
###############################################################################

echo "Show the main window when launching Activity Monitor"
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

echo "Show all processes in Activity Monitor"
defaults write com.apple.ActivityMonitor ShowCategory -int 0

echo "Sort Activity Monitor results by CPU usage"
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
echo "Photos"                                                                 #
###############################################################################

echo "Prevent Photos from opening automatically when devices are plugged in"
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
echo "Keyboard"                           																	  #
###############################################################################

echo "Enable full keyboard access for all controls"
echo "(e.g. enable Tab in modal dialogs)"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "Add Language Layout: greek (el)"
defaults delete com.apple.HIToolbox AppleEnabledInputSources
defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add '<dict>
			<key>InputSourceKind</key>
			<string>Keyboard Layout</string>
			<key>KeyboardLayout ID</key>
			<integer>252</integer>
			<key>KeyboardLayout Name</key>
			<string>ABC</string>
		</dict>'
defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add '<dict>
			<key>InputSourceKind</key>
			<string>Keyboard Layout</string>
			<key>KeyboardLayout ID</key>
			<integer>-18944</integer>
			<key>KeyboardLayout Name</key>
			<string>Greek</string>
		</dict>'

###############################################################################
echo "Safari"		                                                              #
###############################################################################

echo "Prevent Safari from opening ‘safe’ files automatically after downloading"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

echo "Remove useless icons from Safari’s bookmarks bar"
defaults write com.apple.Safari ProxiesInBookmarksBar "()"
