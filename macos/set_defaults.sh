#!/bin/zsh
source 'zsh/functions.sh'
source 'macos/helpers/set_macos_default_if_different.sh'
source 'macos/helpers/set_plist_value_if_different.sh'

sudo -v
echo 'Setting macos defaults'

echo 'Close any open System Preferences panes,'
echo 'to prevent them from overriding'
osascript -e 'tell application "System Preferences" to quit'

echo 'Show the ~/Library folder.'
chflags nohidden ~/Library

set_macos_default_if_different \
	'Disable the crash reporter' \
    'com.apple.CrashReporter' \
    'DialogType' \
    '-string' \
    'none'

set_macos_default_if_different \
	'Improve Bluetooth audio quality' \
    'com.apple.BluetoothAudioAgent' \
    'Apple Bitpool Min (editable)' \
    '-int' \
    40

set_macos_default_if_different \
	'Disable automatic audio device switching' \
    'com.apple.audio.AudioMIDISetup' \
    'Automatic Device Switching' \
    '-bool' \
    false

echo 'Unload Siri Service'
launchctl unload -w \
    /System/Library/LaunchAgents/com.apple.Siri.plist \
    2> /dev/null
set_macos_default_if_different \
	'Remove the Siri menu bar icon' \
    'com.apple.Siri' \
    'StatusMenuVisible' \
    '-int' \
    0
set_macos_default_if_different \
	'Set User Has Declined Enable' \
    'com.apple.Siri' \
    'UserHasDeclinedEnable' \
    '-int' \
    1

echo 'Set FN State to Use F1, F2, etc. keys as'
echo 'standard function keys but it will be media'
echo 'keys with Karabine app'
defaults write -g com.apple.keyboard.fnState \
    -bool true

spctl --master-disable
set_macos_default_if_different \
	'Disable the "Are you sure you want to open this application?" dialog' \
    'com.apple.LaunchServices' \
    'LSQuarantine' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable disk image verification' \
    'com.apple.frameworks.diskimages' \
    'skip-verify' \
    '-bool' \
    true
set_macos_default_if_different \
	'Disable disk image verification for locked images' \
    'com.apple.frameworks.diskimages' \
    'skip-verify-locked' \
    '-bool' \
    true
set_macos_default_if_different \
	'Disable disk image verification for remote images' \
    'com.apple.frameworks.diskimages' \
    'skip-verify-remote' \
    '-bool' \
    true

echo 'Enable snap-to-grid for icons on the'
echo 'desktop and in other icon views'
/usr/libexec/PlistBuddy -c \
    'Set :DesktopViewSettings:IconViewSettings:arrangeBy grid' \
    ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c \
    'Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid' \
    ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c \
    'Set :StandardViewSettings:IconViewSettings:arrangeBy grid' \
    ~/Library/Preferences/com.apple.finder.plist

echo 'Increase grid spacing for icons on the'
echo 'desktop and in other icon views'
/usr/libexec/PlistBuddy -c \
    'Set :DesktopViewSettings:IconViewSettings:gridSpacing 100' \
    ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c \
    'Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100' \
    ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c \
    'Set :StandardViewSettings:IconViewSettings:gridSpacing 100' \
    ~/Library/Preferences/com.apple.finder.plist

echo 'Increase the size of icons on the'
echo 'desktop and in other icon views'
/usr/libexec/PlistBuddy -c \
    'Set :DesktopViewSettings:IconViewSettings:iconSize 100' \
    ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c \
    'Set :FK_StandardViewSettings:IconViewSettings:iconSize 100' \
    ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c \
    'Set :StandardViewSettings:IconViewSettings:iconSize 100' \
    ~/Library/Preferences/com.apple.finder.plist

set_macos_default_if_different \
	'Save to disk (not to iCloud) by default' \
    'NSGlobalDomain' \
    'NSDocumentSaveNewDocumentsToCloud' \
    '-bool' \
    false

set_macos_default_if_different \
	'Add message to Login Windows' \
    '/Library/Preferences/com.apple.loginwindow' \
    'LoginwindowText' \
    'Found this computer? Please contact me at:' \
    'servitola@gmail.com'

set_macos_default_if_different \
	'Set highlight color to green' \
    'NSGlobalDomain' \
    'AppleHighlightColor' \
    '-string' \
    '0.764700 0.976500 0.568600'

set_macos_default_if_different \
	'Disable shadow in screenshots' \
    'com.apple.screencapture' \
    'disable-shadow' \
    '-bool' \
    true

set_macos_default_if_different \
	"Always open everything in Finder's list view" \
    'com.apple.Finder' \
    'FXPreferredViewStyle' \
    'Nlsv'

###############################################################################
echo 'Finder' #
###############################################################################

set_macos_default_if_different \
	'Show Volumes on Desktop' \
    'com.apple.finder' \
    'ShowExternalHardDrivesOnDesktop' \
    '-bool' \
    true

set_macos_default_if_different \
	'Show Volumes on Desktop 2' \
    'com.apple.finder' \
    'ShowRemovableMediaOnDesktop' \
    '-bool' \
    true

set_macos_default_if_different \
	'Show Tab View in Finder windows' \
    'com.apple.finder' \
    'ShowTabView' \
    '-bool' \
    true
set_macos_default_if_different \
	'Show Sidebar in Finder windows' \
    'com.apple.finder' \
    'ShowPathbar' \
    '-bool' \
    true
set_macos_default_if_different \
	'Show Path Bar in Finder windows' \
    'com.apple.finder' \
    'ShowStatusBar' \
    '-bool' \
    true

set_macos_default_if_different \
	'search the current folder by default' \
    'com.apple.finder' \
    'FXDefaultSearchScope' \
    '-string' \
    'SCcf'

set_macos_default_if_different \
	'No .DS_Store files on network volumes' \
    'com.apple.desktopservices' \
    'DSDontWriteNetworkStores' \
    '-bool' \
    true

set_macos_default_if_different \
	"Use list view in all Finder windows by default\nFour-letter codes for the other view modes:'icnv', 'clmv', 'Flwv'" \
    'com.apple.finder' \
    'FXPreferredViewStyle' \
    '-string' \
    'Nlsv'

echo 'Expand the following File Info panes:'
echo ''General', 'Open with', and 'Sharing &
Permissions''
defaults write com.apple.finder \
    FXInfoPanesExpanded \
    -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

###############################################################################
echo 'Activity Monitor' #
###############################################################################

set_macos_default_if_different \
	'Show the main window when launching Activity Monitor' \
    'com.apple.ActivityMonitor' \
    'OpenMainWindow' \
    '-bool' \
    true

set_macos_default_if_different \
	'Show all processes in Activity Monitor' \
    'com.apple.ActivityMonitor' \
    'ShowCategory' \
    '-int' \
    0

set_macos_default_if_different \
	'Sort Activity Monitor results by CPU usage' \
    'com.apple.ActivityMonitor' \
    'SortColumn' \
    '-string' \
    'CPUUsage'
set_macos_default_if_different \
	'Sort Activity Monitor results by CPU usage 2' \
    'com.apple.ActivityMonitor' \
    'SortDirection' \
    '-int' \
    0

###############################################################################
echo 'Photos' #
###############################################################################

defaults -currentHost write \
	'Prevent Photos from opening automatically when devices are plugged in' \
    com.apple.ImageCapture \
    disableHotPlug \
    -bool true

###############################################################################
echo 'Keyboard' #
###############################################################################

set_macos_default_if_different \
	'Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)' \
    'NSGlobalDomain' \
    'AppleKeyboardUIMode' \
    '-int' \
    3

echo 'Add Language Layout: ABC and greek (el)'
defaults delete com.apple.HIToolbox \
    AppleEnabledInputSources
defaults write com.apple.HIToolbox \
    AppleEnabledInputSources \
    -array-add \
    '<dict>
			<key>InputSourceKind</key>
			<string>Keyboard Layout</string>
			<key>KeyboardLayout ID</key>
			<integer>252</integer>
			<key>KeyboardLayout Name</key>
			<string>ABC</string>
		</dict>'
defaults write com.apple.HIToolbox \
    AppleEnabledInputSources \
    -array-add \
    '<dict>
			<key>InputSourceKind</key>
			<string>Keyboard Layout</string>
			<key>KeyboardLayout ID</key>
			<integer>-18944</integer>
			<key>KeyboardLayout Name</key>
			<string>Greek</string>
		</dict>'

###############################################################################
echo 'Keyboard and Text Input Optimization' #
###############################################################################

echo 'Optimize keyboard response'
defaults write -g InitialKeyRepeat -int 25
defaults write -g KeyRepeat -int 6

set_macos_default_if_different \
	'Disable automatic text corrections' \
    'NSGlobalDomain' \
    'NSAutomaticSpellingCorrectionEnabled' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable automatic capitalization' \
    'NSGlobalDomain' \
    'NSAutomaticCapitalizationEnabled' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable automatic period substitution' \
    'NSGlobalDomain' \
    'NSAutomaticPeriodSubstitutionEnabled' \
    '-bool' \
    false

###############################################################################
echo 'Safari' #
###############################################################################

set_macos_default_if_different \
	'Prevent Safari from opening ‘safe’ files automatically after downloading' \
    'com.apple.Safari' \
    'AutoOpenSafeDownloads' \
    '-bool' \
    false

echo
set_macos_default_if_different \
	'Remove icons from Safari’s bookmarks bar' \
    'com.apple.Safari' \
    'ProxiesInBookmarksBar' \
    '()'

set_macos_default_if_different \
	'Show the Develop menu in the menu bar' \
    'com.apple.Safari' \
    'IncludeDevelopMenu' \
    '-bool' \
    true

set_macos_default_if_different \
	'Show the Web Inspector in the Develop menu' \
    'com.apple.Safari' \
    'WebKitDeveloperExtrasEnabledPreferenceKey' \
    '-bool' \
    true

###############################################################################
echo 'Transmission.app' #
###############################################################################

set_macos_default_if_different \
	"Use ~/Documents/Torrents to store incomplete downloads" \
    'org.m0k.transmission' \
    'UseIncompleteDownloadFolder' \
    '-bool' \
    true
set_macos_default_if_different \
	"Set ~/Documents/Torrents to store" \
    'org.m0k.transmission' \
    'IncompleteDownloadFolder' \
    '-string' \
    'Users/servitola/Documents/Torrents'

set_macos_default_if_different \
	"Use ~/Downloads to store completed downloads" \
    'org.m0k.transmission' \
    'DownloadLocationConstant' \
    '-bool' \
    true

set_macos_default_if_different \
	"Don't prompt for confirmation before downloading" \
    'org.m0k.transmission' \
    'DownloadAsk' \
    '-bool' \
    false

set_macos_default_if_different \
	"Don't prompt for confirmation when' opening magnet links" \
    'org.m0k.transmission' \
    'MagnetOpenAsk' \
    '-bool' \
    false

set_macos_default_if_different \
	"Don't prompt for confirmation before removing non-downloading active transfers" \
    'org.m0k.transmission' \
    'CheckRemoveDownloading' \
    '-bool' \
    true

set_macos_default_if_different \
	'Trash original torrent files' \
    'org.m0k.transmission' \
    'DeleteOriginalTorrent' \
    '-bool' \
    true

set_macos_default_if_different \
	'Hide the donate message' \
    'org.m0k.transmission' \
    'WarningDonate' \
    '-bool' \
    false

set_macos_default_if_different \
	'Hide the legal disclaimer' \
    'org.m0k.transmission' \
    'WarningLegal' \
    '-bool' \
    false

echo 'IP block list.'
echo 'Source: https://giuliomac.wordpress.com/2014/02/19/best-blocklist-for-transmission/'
set_macos_default_if_different \
	'Enable the IP block list' \
    'org.m0k.transmission' \
    'BlocklistNew' \
    '-bool' \
    true
set_macos_default_if_different \
	'Set the IP block list URL' \
    'org.m0k.transmission' \
    'BlocklistURL' \
    '-string' \
    'http://john.bitsurge.net/public/biglist.p2p.gz'
set_macos_default_if_different \
	'Enable auto-update of the IP block list' \
    'org.m0k.transmission' \
    'BlocklistAutoUpdate' \
    '-bool' \
    true

set_macos_default_if_different \
	'Randomize port on launch' \
    'org.m0k.transmission' \
    'RandomPort' \
    '-bool' \
    true

###############################################################################
echo 'Mac App Store' #
###############################################################################

set_macos_default_if_different \
	'Enable the WebKit Developer Tools in the Mac App Store' \
    'com.apple.appstore' \
    'WebKitDeveloperExtras' \
    '-bool' \
    true

set_macos_default_if_different \
	'Enable Debug Menu in the Mac App Store' \
    'com.apple.appstore' \
    'ShowDebugMenu' \
    '-bool' \
    true

set_macos_default_if_different \
	'Do not download newly available updates in background' \
    'com.apple.SoftwareUpdate' \
    'AutomaticDownload' \
    '-int' \
    0

set_macos_default_if_different \
	'Do not install System data files & security updates' \
    'com.apple.SoftwareUpdate' \
    'CriticalUpdateInstall' \
    '-int' \
    0

set_macos_default_if_different \
	'Do not automatically download apps purchased on other Macs' \
    'com.apple.SoftwareUpdate' \
    'ConfigDataInstall' \
    '-int' \
    0

###############################################################################
echo 'System Services and Memory Optimization' #
###############################################################################

echo 'Disable automatic software updates'
set_macos_default_if_different \
	'Disable automatic check for updates' \
    '/Library/Preferences/com.apple.SoftwareUpdate' \
    'AutomaticCheckEnabled' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable automatic download of updates' \
    '/Library/Preferences/com.apple.SoftwareUpdate' \
    'AutomaticDownload' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable automatic macOS updates' \
    '/Library/Preferences/com.apple.SoftwareUpdate' \
    'AutomaticallyInstallMacOSUpdates' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable automatic app updates' \
    '/Library/Preferences/com.apple.SoftwareUpdate' \
    'ConfigDataInstall' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable automatic critical updates' \
    '/Library/Preferences/com.apple.SoftwareUpdate' \
    'CriticalUpdateInstall' \
    '-bool' \
    false

set_macos_default_if_different \
	'Disable Natural Language services' \
    'com.apple.assistant.support' \
    'Assistant Enabled' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable Siri Voice Trigger' \
    'com.apple.Siri' \
    'VoiceTriggerEnabled' \
    '-bool' \
    false
set_macos_default_if_different \
	'Disable Dictation' \
    'com.apple.speech.recognition.AppleSpeechRecognition.prefs' \
    'DictationIMIntroMessagePresented' \
    '-bool' \
    true
set_macos_default_if_different \
	'Disable Dictation' \
    'com.apple.speech.recognition.AppleSpeechRecognition.prefs' \
    'ActiveInputAudioDeviceUID' \
    '-string' \
    ''

# Method 1: Using defaults
set_macos_default_if_different \
	'Enable Dark Mode' \
	'.GlobalPreferences' \
	'AppleInterfaceStyle' \
	'-string' \
	'Dark'

# Method 2: Using AppleScript (more reliable)
osascript -e \
    'tell application 'System Events' to tell appearance preferences to set dark mode to true'

# Enable Dark Mode for Terminal.app
set_macos_default_if_different \
	'Set Terminal to use Pro theme in Dark Mode' \
	'com.apple.Terminal' \
	'Default Window Settings' \
	'-string' \
	'Pro'

echo 'Scrolling settings (traditional)'
defaults write -g com.apple.swipescrolldirection -bool false
