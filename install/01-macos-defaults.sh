#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

# domain | key | type | value | what it does (printed only when it changes)
settings=(
    "com.apple.CrashReporter | DialogType | -string | none | no crash reporter dialog"
    "com.apple.audio.AudioMIDISetup | Automatic Device Switching | -bool | false | no automatic audio device switching"
    "com.apple.Siri | StatusMenuVisible | -int | 0 | no Siri icon in the menu bar"
    "com.apple.Siri | UserHasDeclinedEnable | -int | 1 | Siri declined"
    "com.apple.Siri | VoiceTriggerEnabled | -bool | false | no \"Hey Siri\""
    "com.apple.assistant.support | Assistant Enabled | -bool | false | no Natural Language services"
    "com.apple.speech.recognition.AppleSpeechRecognition.prefs | DictationIMIntroMessagePresented | -bool | true | no dictation intro"
    "com.apple.speech.recognition.AppleSpeechRecognition.prefs | ActiveInputAudioDeviceUID | -string |  | no microphone for dictation"
    "com.apple.LaunchServices | LSQuarantine | -bool | false | no \"Are you sure you want to open\" dialog"
    "NSGlobalDomain | NSDocumentSaveNewDocumentsToCloud | -bool | false | save to disk, not iCloud"
    "/Library/Preferences/com.apple.loginwindow | LoginwindowText | -string | Found this computer? Please return it to its owner. | message on the login window"
    "NSGlobalDomain | AppleHighlightColor | -string | 0.764700 0.976500 0.568600 | green highlight"
    "NSGlobalDomain | AppleKeyboardUIMode | -int | 3 | Tab moves through every control"
    "NSGlobalDomain | com.apple.keyboard.fnState | -bool | true | F1–F12 are function keys (Karabiner adds media)"
    "NSGlobalDomain | InitialKeyRepeat | -int | 25 | short delay before key repeat"
    "NSGlobalDomain | KeyRepeat | -int | 6 | fast key repeat"
    "NSGlobalDomain | NSAutomaticSpellingCorrectionEnabled | -bool | false | no autocorrect"
    "NSGlobalDomain | NSAutomaticCapitalizationEnabled | -bool | false | no automatic capitals"
    "NSGlobalDomain | NSAutomaticPeriodSubstitutionEnabled | -bool | false | no period on double space"
    "NSGlobalDomain | com.apple.swipescrolldirection | -bool | false | traditional scrolling"
    "NSGlobalDomain | NSNavPanelExpandedStateForSaveMode | -bool | true | expanded save dialog"
    "NSGlobalDomain | NSNavPanelExpandedStateForSaveMode2 | -bool | true | expanded save dialog (Save As)"
    "NSGlobalDomain | PMPrintingExpandedStateForPrint | -bool | true | expanded print dialog"
    "NSGlobalDomain | PMPrintingExpandedStateForPrint2 | -bool | true | expanded print dialog (2)"
    "com.apple.screencapture | disable-shadow | -bool | true | no shadow on screenshots"
    "com.apple.screencapture | location | -string | $HOME/Pictures/Screenshots | screenshots go to ~/Pictures/Screenshots"
    "com.apple.finder | ShowExternalHardDrivesOnDesktop | -bool | true | external drives on the desktop"
    "com.apple.finder | ShowRemovableMediaOnDesktop | -bool | true | removable media on the desktop"
    "com.apple.finder | ShowTabView | -bool | true | Finder tab bar"
    "com.apple.finder | ShowPathbar | -bool | true | Finder path bar"
    "com.apple.finder | ShowStatusBar | -bool | true | Finder status bar"
    "com.apple.finder | FXDefaultSearchScope | -string | SCcf | Finder searches the current folder"
    "com.apple.finder | FXPreferredViewStyle | -string | Nlsv | Finder list view"
    "com.apple.desktopservices | DSDontWriteNetworkStores | -bool | true | no .DS_Store on network volumes"
    "com.apple.dock | mru-spaces | -bool | false | Spaces keep their order"
    "com.apple.dock | appswitcher-all-displays | -bool | true | ⌘⇥ switcher on every display"
    "com.apple.spaces | spans-displays | -bool | false | each display has its own Spaces"
    "com.apple.ActivityMonitor | OpenMainWindow | -bool | true | Activity Monitor opens its window"
    "com.apple.ActivityMonitor | ShowCategory | -int | 0 | Activity Monitor shows all processes"
    "com.apple.ActivityMonitor | SortColumn | -string | CPUUsage | Activity Monitor sorts by CPU"
    "com.apple.ActivityMonitor | SortDirection | -int | 0 | Activity Monitor sorts descending"
    "com.apple.Terminal | Default Window Settings | -string | Pro | Terminal uses the Pro theme"
    "com.google.Chrome | GenAILocalFoundationalModelSettings | -int | 1 | Chrome downloads no on-device AI model (~4 GB)"
    "com.apple.appstore | WebKitDeveloperExtras | -bool | true | App Store web inspector"
    "com.apple.appstore | ShowDebugMenu | -bool | true | App Store debug menu"
    "com.apple.SoftwareUpdate | AutomaticDownload | -int | 0 | no background update downloads"
    "com.apple.SoftwareUpdate | CriticalUpdateInstall | -int | 0 | no automatic security data updates"
    "com.apple.SoftwareUpdate | ConfigDataInstall | -int | 0 | no apps bought on other Macs"
    "/Library/Preferences/com.apple.SoftwareUpdate | AutomaticDownload | -bool | false | no automatic update downloads"
    "/Library/Preferences/com.apple.SoftwareUpdate | AutomaticallyInstallMacOSUpdates | -bool | false | no automatic macOS updates"
    "/Library/Preferences/com.apple.SoftwareUpdate | ConfigDataInstall | -bool | false | no automatic app updates"
    "/Library/Preferences/com.apple.SoftwareUpdate | CriticalUpdateInstall | -bool | false | no automatic critical updates"
    "org.m0k.transmission | UseIncompleteDownloadFolder | -bool | true | Transmission keeps unfinished downloads apart"
    "org.m0k.transmission | IncompleteDownloadFolder | -string | $HOME/Documents/Torrents | … in ~/Documents/Torrents"
    "org.m0k.transmission | DownloadLocationConstant | -bool | true | Transmission saves to ~/Downloads"
    "org.m0k.transmission | DownloadAsk | -bool | false | Transmission does not ask before downloading"
    "org.m0k.transmission | MagnetOpenAsk | -bool | false | Transmission does not ask for magnet links"
    "org.m0k.transmission | CheckRemoveDownloading | -bool | true | Transmission confirms removing active transfers"
    "org.m0k.transmission | DeleteOriginalTorrent | -bool | true | Transmission trashes .torrent files"
    "org.m0k.transmission | WarningDonate | -bool | false | no Transmission donate message"
    "org.m0k.transmission | WarningLegal | -bool | false | no Transmission legal notice"
    "org.m0k.transmission | BlocklistNew | -bool | true | Transmission IP block list"
    "org.m0k.transmission | BlocklistURL | -string | http://john.bitsurge.net/public/biglist.p2p.gz | … from bitsurge"
    "org.m0k.transmission | BlocklistAutoUpdate | -bool | true | … updated automatically"
    "org.m0k.transmission | RandomPort | -bool | true | Transmission picks a random port"
)

# Layout ids macOS stores for the names in constants.env (LAYOUT_*).
typeset -A layout_ids=( ABC 252 "Russian – PC" 19458 Greek -18944 )
typeset -A layout_names=( ABC ABC "Russian – PC" RussianWin Greek Greek )

changed=0
as_sudo() { [[ $1 == /Library/* ]] && print sudo; }   # the system domain needs root, the rest are the user's

set_default() {  # <domain> <key> <type> <value> <what>
    local current=$($(as_sudo $1) defaults read "$1" "$2" 2>/dev/null || true)
    [[ $3 == -bool ]] && current=${${current/1/true}/0/false}
    [[ $current == "$4" ]] && return
    $(as_sudo $1) defaults write "$1" "$2" "$3" "$4"
    ok "$5"
    changed=$(( changed + 1 ))
}

osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true   # an open pane overwrites what is written here

section "${#settings} settings"
mkdir -p "$HOME/Pictures/Screenshots"
for row in $settings; do
    fields=("${(@s: | :)row}")
    set_default "${fields[@]}"
done

section "input sources from LAYOUT_PRIMARY, LAYOUT_SECONDARY, LAYOUT_TERTIARY"
wanted=()
for layout in "$LAYOUT_PRIMARY" "$LAYOUT_SECONDARY" "$LAYOUT_TERTIARY"; do
    wanted+=("<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>${layout_ids[$layout]:?no id for layout $layout}</integer><key>KeyboardLayout Name</key><string>${layout_names[$layout]}</string></dict>")
done
present=$(defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -o '"KeyboardLayout ID" = [-0-9]*' | grep -o '[-0-9]*$' | sort | tr '\n' ' ')
needed=$(print -l ${layout_ids[$LAYOUT_PRIMARY]} ${layout_ids[$LAYOUT_SECONDARY]} ${layout_ids[$LAYOUT_TERTIARY]} | sort | tr '\n' ' ')
if [[ $present != "$needed" ]]; then
    defaults write com.apple.HIToolbox AppleEnabledInputSources -array "${wanted[@]}"
    ok "$LAYOUT_PRIMARY, $LAYOUT_SECONDARY, $LAYOUT_TERTIARY (after the next login)"
    changed=$(( changed + 1 ))
fi

chflags nohidden "$HOME/Library"
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true   # Photos does not open for a phone
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true
for view in DesktopViewSettings FK_StandardViewSettings StandardViewSettings; do
    for setting in "arrangeBy grid" "gridSpacing 100" "iconSize 100"; do
        /usr/libexec/PlistBuddy -c "Set :$view:IconViewSettings:$setting" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null \
            || true   # these keys exist only once Finder has saved its view settings
    done
done
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
# softwareupdated drops an AutomaticCheckEnabled written by defaults; its own switch sticks.
if [[ $(softwareupdate --schedule) != *off* ]]; then
    sudo softwareupdate --schedule off >/dev/null
    ok "no automatic update checks"
    changed=$(( changed + 1 ))
fi
[[ $(spctl --status) == *disabled* ]] || sudo spctl --master-disable   # macOS then asks to confirm in System Settings

(( changed )) || log "all already set"
