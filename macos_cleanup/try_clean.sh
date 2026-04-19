#!/bin/zsh
# Functions to clean directories and file patterns
# Requires: helpers.sh (spinner, format_size)

try_clean() {
    local DIR="$1"
    local LABEL="${2:-$1}"
    local EXCLUDE="${3:-}"

    if [ ! -d "$DIR" ]; then
        printf "  ${_S_DIM}* $LABEL: not found${_S_NC}\n"
        return
    fi

    if [ -z "$(find "$DIR" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
        printf "  ${_S_DIM}* $LABEL: already empty${_S_NC}\n"
        return
    fi

    spinner_start "$LABEL"

    local SIZE_KB=$(du -sk "$DIR" 2>/dev/null | cut -f1)

    if [ -z "$SIZE_KB" ] || [ "$SIZE_KB" -le 0 ]; then
        spinner_stop_dim "$LABEL: already empty"
        return
    fi

    local ERROR_OUTPUT
    if [ -n "$EXCLUDE" ]; then
        ERROR_OUTPUT=$(sudo find "$DIR" -mindepth 1 -maxdepth 1 -not -name "$EXCLUDE" -exec rm -rf {} + 2>&1 </dev/null)
    else
        ERROR_OUTPUT=$(sudo find "$DIR" -mindepth 1 -delete 2>&1 </dev/null)
    fi

    if [ $? -eq 0 ]; then
        spinner_stop "$LABEL: cleaned ($(format_size $SIZE_KB))"
    else
        spinner_stop_error "$LABEL: ERROR - failed to clean. $ERROR_OUTPUT"
    fi
}

try_clean_pattern() {
    local BASE_PATH="$1"
    local TYPE="$2"
    local PATTERN="$3"
    local LABEL="${4:-$PATTERN in $BASE_PATH}"

    if [ ! -d "$BASE_PATH" ]; then
        printf "  ${_S_DIM}* $LABEL: not found${_S_NC}\n"
        return
    fi

    spinner_start "$LABEL"

    local MATCHES=$(find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$MATCHES" -eq 0 ]; then
        spinner_stop_dim "$LABEL: nothing to clean"
        return
    fi

    local SIZE_KB=$(find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')

    local ERROR_OUTPUT
    if [ "$TYPE" = "d" ]; then
        ERROR_OUTPUT=$(sudo find "$BASE_PATH" -type d -name "$PATTERN" -exec rm -rf {} \; 2>&1 </dev/null)
    else
        ERROR_OUTPUT=$(sudo find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" -delete 2>&1 </dev/null)
    fi

    if [ $? -eq 0 ]; then
        spinner_stop "$LABEL: cleaned ($MATCHES items, $(format_size $SIZE_KB))"
    else
        spinner_stop_error "$LABEL: ERROR - failed to clean. $ERROR_OUTPUT"
    fi
}
