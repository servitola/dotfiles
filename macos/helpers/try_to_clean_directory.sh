#!/bin/zsh

# Usage: clean_dir.sh <path> <label>
# Example: clean_dir.sh ~/Library/Caches

DIR="$1"
LABEL="${2:-$1}"

source "$(dirname "$0")/spinner.sh"

if [ ! -d "$DIR" ]; then
    printf "  ${_S_DIM}* $LABEL: not found${_S_NC}\n"
    exit 0
fi

if [ -z "$(find "$DIR" -mindepth 1 -maxdepth 1 2> /dev/null)" ]; then
    printf "  ${_S_DIM}* $LABEL: already empty${_S_NC}\n"
    exit 0
fi

# Start spinner before measuring size — du can be slow on large dirs
spinner_start "$LABEL"

SIZE_KB=$(du -sk "$DIR" 2>/dev/null | cut -f1)

if [ -z "$SIZE_KB" ] || [ "$SIZE_KB" -le 0 ]; then
    spinner_stop_dim "$LABEL: already empty"
    exit 0
fi

if [ "$SIZE_KB" -ge 1048576 ]; then
    SIZE_HUMAN="$(( SIZE_KB / 1048576 )) GB"
elif [ "$SIZE_KB" -ge 1024 ]; then
    SIZE_HUMAN="$(( SIZE_KB / 1024 )) MB"
else
    SIZE_HUMAN="${SIZE_KB} KB"
fi

# Clean with sudo directly
ERROR_OUTPUT=$(sudo find "$DIR" -mindepth 1 -delete 2>&1)

if [ $? -eq 0 ]; then
    spinner_stop "$LABEL: cleaned ($SIZE_HUMAN)"
else
    spinner_stop_error "$LABEL: ERROR - failed to clean. $ERROR_OUTPUT"
fi
