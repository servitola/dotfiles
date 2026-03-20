#!/bin/zsh

# Background spinner for cleanup operations
# Usage:
#   source spinner.sh
#   spinner_start "Label"
#   <do work>
#   spinner_stop "result message"   # green bold
#   spinner_stop_dim "result message"  # dim (for errors)

_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
_SPINNER_PID=""
_SPINNER_LABEL=""

_S_GREEN='\033[0;92m'
_S_DIM='\033[2m'
_S_BOLD='\033[1m'
_S_NC='\033[0m'
_S_CLR='\033[K'
_S_YELLOW='\033[0;33m'

spinner_start() {
    setopt LOCAL_OPTIONS NO_MONITOR
    _SPINNER_LABEL="$1"
    (
        i=0
        while true; do
            printf "\r${_S_CLR}  ${_S_DIM}${_SPINNER_FRAMES[$(( i % 10 + 1 ))]} ${_SPINNER_LABEL}${_S_NC}"
            i=$(( i + 1 ))
            sleep 0.08
        done
    ) &
    _SPINNER_PID=$!
}

spinner_stop() {
    setopt LOCAL_OPTIONS NO_MONITOR
    kill $_SPINNER_PID 2>/dev/null
    wait $_SPINNER_PID 2>/dev/null
    printf "\r${_S_CLR}  ${_S_GREEN}${_S_BOLD}* $1${_S_NC}\n"
    _SPINNER_PID=""
}

spinner_stop_dim() {
    setopt LOCAL_OPTIONS NO_MONITOR
    kill $_SPINNER_PID 2>/dev/null
    wait $_SPINNER_PID 2>/dev/null
    printf "\r${_S_CLR}  ${_S_DIM}* $1${_S_NC}\n"
    _SPINNER_PID=""
}

spinner_stop_error() {
    setopt LOCAL_OPTIONS NO_MONITOR
    kill $_SPINNER_PID 2>/dev/null
    wait $_SPINNER_PID 2>/dev/null
    printf "\r${_S_CLR}  ${_S_YELLOW}* $1${_S_NC}\n"
    _SPINNER_PID=""
}
