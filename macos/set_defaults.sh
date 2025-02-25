#!/bin/zsh
source "zsh/functions.sh"

sudo -v
echo "Setting macos defaults"

echo "Close any open System Preferences panes, to prevent them from overriding"
osascript -e 'tell application "System Preferences" to quit'

echo "Show the ~/Library folder."
chflags nohidden ~/Library

echo "Disable the sound effects on boot"
nvram SystemAudioVolume=" "

echo Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

echo "Improve Bluetooth audio quality"
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

echo "Disable automatic audio device switching"
defaults write com.apple.audio.AudioMIDISetup "Automatic Device Switching" -bool false

echo "Disable Siri and remove the menu bar icon"
launchctl unload -w /System/Library/LaunchAgents/com.apple.Siri.plist 2> /dev/null
defaults write com.apple.Siri StatusMenuVisible -int 0
defaults write com.apple.Siri UserHasDeclinedEnable -int 1

echo "Set FN State to Use F1, F2, etc. keys as standard function keys but it will be media keys with Karabine app"
defaults write -g com.apple.keyboard.fnState -bool true

echo "Disable the “Are you sure you want to open this application?” dialog"
spctl --master-disable
defaults write com.apple.LaunchServices LSQuarantine -bool false
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

echo "Enable snap-to-grid for icons on the desktop and in other icon views"
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

echo "Increase grid spacing for icons on the desktop and in other icon views"
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

echo "Increase the size of icons on the desktop and in other icon views"
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 100" ~/Library/Preferences/com.apple.finder.plist

echo "Save to disk (not to iCloud) by default"
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

echo "Add message to Login Windows"
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText  "Found this computer? Please contact me at: servitola@gmail.com"

echo "Set highlight color to green"
defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

echo "Disable shadow in screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

echo "Always open everything in Finder's list view. This is important."
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

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

echo "Add Language Layout: ABC and greek (el)"
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
echo "Keyboard and Text Input Optimization"                                   #
###############################################################################

echo "Optimize keyboard response"
defaults write -g InitialKeyRepeat -int 25
defaults write -g KeyRepeat -int 6

echo "Disable automatic text corrections"
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

###############################################################################
echo "Safari"		                                                              #
###############################################################################

echo "Prevent Safari from opening ‘safe’ files automatically after downloading"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

echo "Remove useless icons from Safari’s bookmarks bar"
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

###############################################################################
echo "Transmission.app"                                                       #
###############################################################################

echo "Use `~/Documents/Torrents` to store incomplete downloads"
defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Documents/Torrents"

echo "Use `~/Downloads` to store completed downloads"
defaults write org.m0k.transmission DownloadLocationConstant -bool true

echo "Don’t prompt for confirmation before downloading"
defaults write org.m0k.transmission DownloadAsk -bool false
defaults write org.m0k.transmission MagnetOpenAsk -bool false

echo "Don’t prompt for confirmation before removing non-downloading active transfers"
defaults write org.m0k.transmission CheckRemoveDownloading -bool true

echo "Trash original torrent files"
defaults write org.m0k.transmission DeleteOriginalTorrent -bool true

echo "Hide the donate message"
defaults write org.m0k.transmission WarningDonate -bool false
echo "Hide the legal disclaimer"
defaults write org.m0k.transmission WarningLegal -bool false

echo "IP block list."
echo "Source: https://giuliomac.wordpress.com/2014/02/19/best-blocklist-for-transmission/"
defaults write org.m0k.transmission BlocklistNew -bool true
defaults write org.m0k.transmission BlocklistURL -string "http://john.bitsurge.net/public/biglist.p2p.gz"
defaults write org.m0k.transmission BlocklistAutoUpdate -bool true

echo "Randomize port on launch"
defaults write org.m0k.transmission RandomPort -bool true

###############################################################################
echo "Mac App Store"                                                          #
###############################################################################

echo "Enable the WebKit Developer Tools in the Mac App Store"
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

echo "Enable Debug Menu in the Mac App Store"
defaults write com.apple.appstore ShowDebugMenu -bool true

echo "Do not download newly available updates in background"
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 0

echo "Do not install System data files & security updates"
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 0

echo "Do not automatically download apps purchased on other Macs"
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 0

###############################################################################
echo "System Services and Memory Optimization"                                #
###############################################################################

echo "Disable automatic software updates"
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false

echo "Disable Natural Language services"
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri VoiceTriggerEnabled -bool false
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMIntroMessagePresented -bool true
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs ActiveInputAudioDeviceUID -string ""

echo "Enable Dark Mode"
# Method 1: Using defaults
defaults write .GlobalPreferences AppleInterfaceStyle -string "Dark"
# Method 2: Using AppleScript (more reliable)
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# Enable Dark Mode for Terminal.app too
defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"
