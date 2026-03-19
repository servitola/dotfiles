# update all
alias up='source ~/projects/dotfiles/macos/update_all_and_cleanup_all.sh'

# wallpapers blocklist: block and delete a wallpaper by filename
wallblock() {
    local file="$1"
    local blocklist="$HOME/projects/dotfiles/macos/wallpapers-blocklist.txt"
    if [[ -z "$file" ]]; then
        echo "Usage: wallblock <filename>"
        return 1
    fi
    echo "$file" >> "$blocklist"
    /bin/rm -f "$HOME/Pictures/Wallpapers/GruvBox/$file"
    echo "Blocked and deleted: $file"
}

alias u=up

alias a="claude -c"
alias c="claude"
alias q="qwen"

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
alias ya="yi && yb && yc"

# download from YouTube
alias ytvideo="yt-dlp --config-location ~/projects/dotfiles/yt-dlp/videoConfig"
alias ytv=ytvideo
alias ytaudio="yt-dlp --config-location ~/projects/dotfiles/yt-dlp/audioConfig"
alias yta=ytaudio

alias cl=clear
# Only alias cd to z in interactive shells where zoxide is available
if [[ -o interactive ]] && command -v __zoxide_z &> /dev/null; then
    alias cd='z'
fi

# duckduckgo search
alias d="ddgr -x -n 3"

alias code2=windsurf
alias cpwd="pwd|tr -d '\n'|pbcopy"

alias sudo='sudo '
alias rm="trash"
alias realrm="/bin/rm"
alias cat=bat
alias mkdir="mkdir -pv"
alias search=rg
alias e=eza
alias top=btop
alias ping="prettyping -c 10 --nolegend"

# screen recording
rec() {
    ffmpeg -f avfoundation -framerate 30 -video_size 1920x1080 -pixel_format uyvy422 -f avfoundation -i "2" -preset ultrafast -c:a pcm_s16le -probesize 100M "output_$(date +%Y%m%d_%H%M%S).mp4"
}

# ANDROID ADB
android_deep_link() { adb shell am start -a android.intent.action.VIEW -d "$1"; }
alias android_deep_link_to_Development='android_deep_link https://ct.spotware.com'
android_run_emulator() { emulator -avd "$(emulator -list-avds | head -1)" & }
android_paste_to_emulator() { adb shell input text "$1"; }
alias android_uninstall_app='adb shell pm uninstall --user 0 com.dev.ct.dev'
alias android_uninstall_app_leave_data='adb shell pm uninstall -k --user 0 com.dev.ct.dev'
alias android_clean_data_for_app='adb shell pm clear --user 0 com.dev.ct.dev'
alias android_list_real_devices='adb usb'

alias path='echo -e ${PATH//:/\\n}'

alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | rg -o 'inet6?\s+(addr:\s*)?(((\d+\.){3}\d+)|[a-fA-F0-9:]+)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias ports='netstat -vanp tcp'
alias ports_listeners='lsof -nP -iTCP -sTCP:LISTEN'

# eza aliases (theme from ~/.config/eza/theme.yml)
alias ls="eza --icons --group-directories-first --color=always"
alias l="eza --icons --group-directories-first --color=always"
alias ll="ls -l"
alias la="ll -a"
alias lt="ll --tree"

# brew
alias bi="brew install"
alias bic="brew install --cask"
alias bu="brew uninstall"

# voice to text transcription
alias w='whisper_max'
alias wv='whisper_voice'

# quality voice to text transcription
function whisper_max() {
    ~/projects/whisper-mps-lang/venv/bin/whisper-mps  --file-name "$1" --model-name large-v3 --language ru 2>/dev/null
}

# fast voice to text transcription
function whisper_voice() {
    ~/projects/whisper-mps-lang/venv/bin/whisper-mps  --file-name "$1" --model-name medium --language ru 2>/dev/null
}

alias lg="lazygit"
alias ld="lazydocker"

# File manager
alias ff="open -a 'Marta' ."
