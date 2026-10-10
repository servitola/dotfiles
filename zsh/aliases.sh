# Guard: skip if already loaded
[[ -n "$_ALIASES_LOADED" ]] && return 0
export _ALIASES_LOADED=1

# update all
alias up='source ~/projects/dotfiles/macos/update_all_and_cleanup_all.sh'
alias u=up
alias deepclean='zsh ~/projects/dotfiles/macos_cleanup/deep_clean.sh'

alias perfcheck='~/projects/dotfiles/zsh/bin/perfcheck'
alias perf=perfcheck

# Switch this shell's default node from brew's latest to the keg-only node@22
# (needed by one work project). Prepend so it wins over /opt/homebrew/bin.
alias use-node22='path=("/opt/homebrew/opt/node@22/bin" $path)'

alias a="claude -c"
alias c="claude"

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
alias ytvideo="noglob yt-dlp --config-location ~/projects/dotfiles/yt-dlp/videoConfig"
alias ytv=ytvideo
alias ytaudio="noglob yt-dlp --config-location ~/projects/dotfiles/yt-dlp/audioConfig"
alias yta=ytaudio

# Rutube: same video config, retried through the Moscow exit when geo-blocked
alias ytrutube="noglob yt-rutube"
alias ytr=ytrutube

alias cl=clear
# cd → zoxide's `z` for frecency jumps in interactive use.
# Hidden from AI agents (Claude Code sets CLAUDECODE=1): `z` fuzzy-matches against
# history, so a relative `cd <name>` that doesn't exist locally silently teleports
# to a frecency match instead of erroring — agents then run in the wrong dir.
# Agents get plain cd; you keep the frecency jumps.
[[ -z "$CLAUDECODE" ]] && alias cd='z'

# duckduckgo search
alias d="ddgr -x -n 3"

alias cpwd="pwd|tr -d '\n'|pbcopy"

alias sudo='sudo '
alias cat=bat
alias mkdir="mkdir -pv"
alias search=rg
alias e=eza
# top → btop (rich TUI) for interactive use.
# Hidden from AI agents (CLAUDECODE set): btop is a full-screen TUI that ignores
# top's batch flags (-l/-b/-n) and hangs waiting for input. Agents get plain top.
[[ -z "$CLAUDECODE" ]] && alias top=btop
# ping → prettyping (compact unicode graph) for interactive use.
# Hidden from AI agents (CLAUDECODE set): prettyping renders colored unicode bars
# instead of standard ping lines and forces -c 10, so agents parsing latency/loss
# get garbage. Agents get plain ping.
[[ -z "$CLAUDECODE" ]] && alias ping="prettyping -c 10 --nolegend"

rec() {
    ffmpeg -f avfoundation -framerate 30 -video_size 1920x1080 -pixel_format uyvy422 -f avfoundation -i "2" -preset ultrafast -c:a pcm_s16le -probesize 100M "output_$(date +%Y%m%d_%H%M%S).mp4"
}

android_deep_link() { adb shell am start -a android.intent.action.VIEW -d "$1"; }
alias android_deep_link_to_Development='android_deep_link https://ct.workname.com'
android_run_emulator() { emulator -avd "$(emulator -list-avds | head -1)" & }
android_vpn() { android_run_emulator && sleep 10 && adb shell settings put global http_proxy 10.0.2.2:8118; }
dotnet_vpn() { HTTP_PROXY=$PROXY_WORK_HTTP HTTPS_PROXY=$PROXY_WORK_HTTP dotnet "$@"; }
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

# Theme lives in ~/.config/eza/theme.yml.
# Hidden from AI agents (CLAUDECODE set): `--color=always --icons` inject ANSI
# escapes and glyph icons even into pipes, so agents parsing `ls` output get
# garbage. Interactive shells keep the pretty listing; agents fall back to /bin/ls.
if [[ -z "$CLAUDECODE" ]]; then
    alias ls="eza --icons --group-directories-first --color=always"
    alias l="eza --icons --group-directories-first --color=always"
    alias ll="ls -l"
    alias la="ll -a"
    alias lt="ll --tree"
fi

# brew
alias bi="brew install"
alias bic="brew install --cask"
alias bu="brew uninstall"

# text to speech (Russian, local Piper TTS)
alias say-ru='piper_say'

function piper_say() {
    local text="${*:-$(cat)}"
    echo "$text" | ~/.venv/tts/bin/python -m piper \
        --model ~/.local/share/piper-voices/ru_RU-irina-medium.onnx \
        --output_file /tmp/piper_out.wav 2>/dev/null \
    && afplay /tmp/piper_out.wav
}

alias w='whisper_max'
alias wv='whisper_voice'

function whisper_max() {
    whisper-mps --file-name "$1" --model-name large-v3 --language ru 2>/dev/null
}

# fast voice to text transcription
function whisper_voice() {
    whisper-mps --file-name "$1" --model-name medium --language ru 2>/dev/null
}

alias lg="lazygit"
alias g="lazygit"
alias ga="git add -A && git commit -m \"1\""
alias ld="lazydocker"

alias ff="open -a 'Marta' ."

# Live log viewer for serho (Telegram AI agent) — q quit, / search, ? help
alias serho-logs="lnav $HOME/Library/Logs/serho/stdout.log $HOME/Library/Logs/serho/stderr.log"

ppp() { readlink -f "${1:-.}" | tr -d '\n' | pbcopy && echo "Copied: $(pbpaste)"; }

alias recomp='~/projects/serho_topics/видео-пережать/recompress_one.sh REPLACE'
