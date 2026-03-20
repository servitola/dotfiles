#!/bin/zsh

# Usage: try_to_clean_by_pattern.sh <base_path> <type> <pattern> <label>
# Examples:
#   try_to_clean_by_pattern.sh ~/Library/Logs f "*.log" "Log files"
#   try_to_clean_by_pattern.sh . d ".AppleD*" "Apple Double files"

BASE_PATH="$1"
TYPE="$2" # f=file, d=directory
PATTERN="$3"
LABEL="${4:-$PATTERN in $BASE_PATH}"

source "$(dirname "$0")/spinner.sh"

if [ ! -d "$BASE_PATH" ]; then
    printf "  ${_S_DIM}* $LABEL: not found${_S_NC}\n"
    exit 0
fi

# Start spinner before scanning — find across ~ can be slow
spinner_start "$LABEL"

# Check if any matches exist
MATCHES=$(find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" 2> /dev/null | wc -l | tr -d ' ')

if [ "$MATCHES" -eq 0 ]; then
    spinner_stop_dim "$LABEL: nothing to clean"
    exit 0
fi

# Calculate size before cleaning
SIZE_KB=$(find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')

if [ "$SIZE_KB" -ge 1048576 ]; then
    SIZE_HUMAN="$(( SIZE_KB / 1048576 )) GB"
elif [ "$SIZE_KB" -ge 1024 ]; then
    SIZE_HUMAN="$(( SIZE_KB / 1024 )) MB"
else
    SIZE_HUMAN="${SIZE_KB} KB"
fi

# Delete matches with sudo directly
if [ "$TYPE" = "d" ]; then
    ERROR_OUTPUT=$(sudo find "$BASE_PATH" -type d -name "$PATTERN" -exec rm -rf {} \; 2>&1)
else
    ERROR_OUTPUT=$(sudo find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" -delete 2>&1)
fi

if [ $? -eq 0 ]; then
    spinner_stop "$LABEL: cleaned ($MATCHES items, $SIZE_HUMAN)"
else
    spinner_stop_error "$LABEL: ERROR - failed to clean. $ERROR_OUTPUT"
fi
