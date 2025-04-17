# update all
alias up='zsh ~/projects/dotfiles/macos/update_all_and_cleanup_all.sh'
alias u=up

# reload zsh settings
alias reload="exec zsh"
alias re=reload

# yarn
alias y=yarn
alias yi="yarn install"
alias yb="yarn build"
alias yd="yarn dev"
alias yl="yarn lint"
alias yc="yarn check-all"

# download from YouTube
alias ytvideo="yt-dlp --config-location ~/projects/dotfiles/yt-dlp/videoConfig"
alias ytv=ytvideo
alias ytaudio="yt-dlp --config-location ~/projects/dotfiles/yt-dlp/audioConfig"
alias yta=ytaudio

alias c=clear
# duckduckgo search
alias d="ddgr -x -n 3"

alias gtop=btop
alias code2=windsurf
alias cpwd="pwd|tr -d '\n'|pbcopy"

alias rm=rm -f
alias cat=bat
alias mkdir="mkdir -pv"
alias grep='grep --color=auto'
alias search=grep
alias python=python3
alias pip=pip3
alias wifi=airport
alias ls=eza
alias e=eza
alias f=fzf
alias htop=btop
alias t=btop
alias b=btop
# -i \"2:2\"
alias rec="ffmpeg -f avfoundation -framerate 30 -video_size 1920x1080 -pixel_format uyvy422  -f avfoundation -i \"2\" -preset ultrafast -c:a pcm_s16le -probesize 100M \"output_$(date +%Y%m%d_%H%M%S).mp4\""

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

# Load eza colors
source ~/projects/dotfiles/eza/colors.sh

# eza aliases with custom theme
alias ls="eza --icons --group-directories-first --color=always"
alias l="ls"
alias ll="ls -l"
alias la="ll -a"
alias lt="ll --tree"
