#!/bin/zsh
# Spinner and utility functions for cleanup scripts

# --- Spinner ---

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
    kill $_SPINNER_PID 2>/dev/null
    wait $_SPINNER_PID 2>/dev/null
    printf "\r${_S_CLR}  ${_S_GREEN}${_S_BOLD}* $1${_S_NC}\n"
    _SPINNER_PID=""
}

spinner_stop_dim() {
    kill $_SPINNER_PID 2>/dev/null
    wait $_SPINNER_PID 2>/dev/null
    printf "\r${_S_CLR}  ${_S_DIM}* $1${_S_NC}\n"
    _SPINNER_PID=""
}

spinner_stop_error() {
    kill $_SPINNER_PID 2>/dev/null
    wait $_SPINNER_PID 2>/dev/null
    printf "\r${_S_CLR}  ${_S_YELLOW}* $1${_S_NC}\n"
    _SPINNER_PID=""
}

# --- Utilities ---

format_size() {
    local kb=$1
    if [ "$kb" -ge 1048576 ]; then
        echo "$(( kb / 1048576 )) GB"
    elif [ "$kb" -ge 1024 ]; then
        echo "$(( kb / 1024 )) MB"
    else
        echo "${kb} KB"
    fi
}
