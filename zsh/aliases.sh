# ZSH
alias up='zsh ~/projects/dotfiles/macos/update_all_and_cleanup_all.sh'
alias reload=". ~/.zshrc && echo 'ZSH config reloaded from ~/.zshrc'"

alias re=reload
alias cat=bat
alias rm=trash
alias mkdir="mkdir -pv"
alias grep='grep --color=auto'
alias search=grep
alias python=python3
alias pip=pip3
alias wifi=airport
alias ls=exa
alias wifi=airport

# ANDROID ADB
alias android_deep_link='f() { adb shell am start -a android.intent.action.VIEW -d "$1" }; f'
alias android_deep_link_to_Development='android_deep_link https://ct.spotware.com'
alias android_run_emulator='emulator -avd $(emulator -list-avds| head -1) &'
alias android_paste_to_emulator='f() { adb shell input text "${1}" }; f'
alias android_uninstall_app='adb shell pm uninstall --user 0 com.dev.ct.dev'
alias android_uninstall_app_leave_data='adb shell pm uninstall -k --user 0 com.dev.ct.dev'
alias android_clean_data_for_app='adb shell pm clear –user 0 com.dev.ct.dev'
alias android_list_real_devices='adb usb'
alias android_download_dev_db='adb pull /sdcard/test.txt ~/projects/com.dev.ct.dev.mementoes.db'
alias android_upload_dev_db='adb push ~/projects/com.dev.ct.dev.mementoes.db /sdcard/test.txt'

# iOS
alias ios_run_emulator="open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
alias path_display='echo -e ${PATH//:/\\n}'

alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias wifis="wifi -s"
alias ports='netstat -vanp tcp'
alias ports_listeners='lsof -nP -iTCP -sTCP:LISTEN'

# EXA aliases                                                       # ls
alias l='exa -lbF --git'                                               # list, size, type, git
alias ll='exa -lbGF --git'                                             # long list
alias llm='exa -lbGF --git --sort=modified'                            # long list, modified date sort
alias la='exa -lbhHigUmuSa --time-style=long-iso --git --color-scale'  # all list
alias lx='exa -lbhHigUmuSa@ --time-style=long-iso --git --color-scale' # all + extended list
alias lS='exa -1'			                                                  # one column, just names
alias lt='exa --tree --level=2'
# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"
