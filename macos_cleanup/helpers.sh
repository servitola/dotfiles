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
    setopt LOCAL_OPTIONS NO_MONITOR
    _SPINNER_LABEL="$1"
    # Only animate on a real terminal — when output is captured (logs, an AI's
    # Bash tool) the \r-based frames would flood thousands of lines of noise.
    if [ ! -t 1 ]; then
        _SPINNER_PID=""
        return
    fi
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
    attention "$1"
}

# --- Utilities ---

# One line for the «Требует внимания» summary that `up` prints at the end.
attention() { print -r -- "$*" >> "${UP_ATTENTION:-/dev/null}" }

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

# uv keeps the environment of a `uv run script.py` service inside its cache
# (environments-v2), and both `uv cache prune` and `uv cache clean` delete it
# under the live process. The process keeps serving until its next lazy import,
# then answers 500 with ModuleNotFoundError — seen on piper-shim and kokoro-shim.
# Restarting makes uv rebuild the environment.
restart_services_with_deleted_uv_env() {
    local cache_dir="$1" parent_pid python label
    ps -axo ppid=,command= | awk -v c="$cache_dir/" 'index($2, c) == 1 {print $1, $2}' \
        | while read -r parent_pid python; do
            [ -e "$python" ] && continue
            label=$(launchctl list | awk -v p="$parent_pid" '$1 == p {print $3}')
            [ -n "$label" ] || continue
            launchctl kickstart -k "gui/$UID/$label"
            printf "  ${_S_DIM}* restarted $label (its uv environment was removed)${_S_NC}\n"
        done
}
