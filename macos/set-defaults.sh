#!/usr/bin/env bash

sudo -v

# close any open System Preferences panes, to prevent them from overriding
osascript -e 'tell application "System Preferences" to quit'

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Disable Siri and remove the menu bar icon
launchctl unload -w /System/Library/LaunchAgents/com.apple.Siri.plist 2> /dev/null
defaults write com.apple.Siri StatusMenuVisible -int 0
defaults write com.apple.Siri UserHasDeclinedEnable -int 1

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Add message to Login Windows
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText  "Found this computer? Please contact me at: servitola@gmail.com"

# Set highlight color to green
defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Set Dock to the right
defaults write com.apple.dock "orientation" -string "right"

# Dim hidden apps
defaults write com.apple.dock showhidden -bool true

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Show the ~/Library folder.
chflags nohidden ~/Library

###############################################################################
# Finder                                                                      #
###############################################################################

# Set the Finder prefs for showing a few different volumes on the Desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

defaults write com.apple.finder ShowTabView -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true


###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Photos                                                                      #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Keyboard																	  #
###############################################################################

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Add Language Layouts: en, ru, el
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
			<integer>19458</integer>
			<key>KeyboardLayout Name</key>
			<string>RussianWin</string>
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
# Safari		                                                              #
###############################################################################

# Prevent Safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Remove useless icons from Safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"