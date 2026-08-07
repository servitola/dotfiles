#!/bin/zsh
# Functions to clean directories and file patterns
# Requires: helpers.sh (spinner, format_size)

: "${CLEANUP_KEEP_DAYS:=2}"

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

# Age-gated cleaning comes in two shapes, and picking the wrong one either
# corrupts a cache or never frees anything. The deciding question is what a
# top-level entry means:
#
#   try_clean_aged       — the entry is one self-contained unit of work
#                          (DerivedData/<project>, _npx/<hash>, a Steam
#                          download). Its files are only meaningful together,
#                          so the unit lives or dies whole.
#   try_clean_aged_files — the entry is a bag of independently replaceable
#                          artifacts (a Maven/NuGet jar cache, a log dir).
#                          Whole-unit gating is useless here: one warm jar in
#                          modules-2 would pin the other several GB forever.
#
# Do NOT move an app cache (~/Library/Caches/<bundle>, browser CEF dirs) to the
# per-file shape. There a fresh index file references stale data files, and
# deleting only the stale half leaves the app worse off than an absent cache —
# which is exactly what plain try_clean gives it.

# A top-level entry goes only when no *file* under it was modified in the last
# $DAYS days. Two things make the naive check wrong: a directory's own mtime
# doesn't move when a nested file changes (so it can look stale while a build
# writes inside it), and it *does* move on every add/remove (so a dir of ancient
# junk can look fresh). Hence the recursive -type f probe. A find that errors
# out (unreadable subtree) is read as "in use" and kept.
try_clean_aged() {
    local DIR="$1"
    local LABEL="${2:-$1}"
    local EXCLUDE="${3:-}"
    local DAYS="${4:-$CLEANUP_KEEP_DAYS}"

    if [ ! -d "$DIR" ]; then
        printf "  ${_S_DIM}* $LABEL: not found${_S_NC}\n"
        return
    fi

    spinner_start "$LABEL"

    local -a STALE=()
    local entry fresh
    for entry in "$DIR"/*(ND); do
        [ -n "$EXCLUDE" ] && [[ "${entry:t}" == ${~EXCLUDE} ]] && continue
        fresh=$(find "$entry" -type f -mtime -"$DAYS" -print -quit 2>/dev/null) || continue
        [ -n "$fresh" ] && continue
        STALE+=("$entry")
    done

    if [ ${#STALE[@]} -eq 0 ]; then
        spinner_stop_dim "$LABEL: nothing older than ${DAYS}d"
        return
    fi

    local SIZE_KB=$(du -sk "${STALE[@]}" 2>/dev/null | awk '{s+=$1} END {print s+0}')

    local ERROR_OUTPUT
    ERROR_OUTPUT=$(sudo "${RM_CMD:-/bin/rm}" -rf -- "${STALE[@]}" 2>&1 </dev/null)

    if [ $? -eq 0 ]; then
        spinner_stop "$LABEL: cleaned ${#STALE[@]} items older than ${DAYS}d ($(format_size $SIZE_KB))"
    else
        spinner_stop_error "$LABEL: ERROR - failed to clean. $ERROR_OUTPUT"
    fi
}

# Per-file age gate: every file untouched for $DAYS days goes, then the
# directories left empty behind them. `! -mtime -$DAYS` is the exact complement
# of the freshness test above — `-mtime +$DAYS` is not, it truncates to whole
# days and would spare a whole extra day's worth.
try_clean_aged_files() {
    local DIR="$1"
    local LABEL="${2:-$1}"
    local DAYS="${3:-$CLEANUP_KEEP_DAYS}"

    if [ ! -d "$DIR" ]; then
        printf "  ${_S_DIM}* $LABEL: not found${_S_NC}\n"
        return
    fi

    spinner_start "$LABEL"

    local SIZE_KB=$(sudo find "$DIR" -type f ! -mtime -"$DAYS" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    local COUNT=$(sudo find "$DIR" -type f ! -mtime -"$DAYS" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$COUNT" -eq 0 ]; then
        spinner_stop_dim "$LABEL: nothing older than ${DAYS}d"
        return
    fi

    local ERROR_OUTPUT
    ERROR_OUTPUT=$(sudo find "$DIR" -type f ! -mtime -"$DAYS" -delete 2>&1 </dev/null)

    if [ $? -eq 0 ]; then
        sudo find "$DIR" -mindepth 1 -type d -empty -delete 2>/dev/null
        spinner_stop "$LABEL: cleaned $COUNT files older than ${DAYS}d ($(format_size $SIZE_KB))"
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
