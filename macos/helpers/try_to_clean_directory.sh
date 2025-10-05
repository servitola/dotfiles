#!/bin/bash

# Usage: clean_dir.sh <path> <label>
# Example: clean_dir.sh ~/Library/Caches

DIR="$1"
LABEL="${2:-$1}"

if [ ! -d "$DIR" ]; then
    echo "  * $LABEL: directory not found"
    exit 0
fi

if [ -z "$(find "$DIR" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
    echo "  * $LABEL: already empty"
    exit 0
fi

ERROR_OUTPUT=$(find "$DIR" -mindepth 1 -delete 2>&1)

if [ $? -eq 0 ]; then
    echo "  * $LABEL: cleaned"
else
    echo "  * $LABEL: Warn - failed to clean. $ERROR_OUTPUT"
    exit 0
fi
