#!/bin/zsh

# Usage: try_to_clean_by_pattern.sh <base_path> <type> <pattern> <label>
# Examples:
#   try_to_clean_by_pattern.sh ~/Library/Logs f "*.log" "Log files"
#   try_to_clean_by_pattern.sh . d ".AppleD*" "Apple Double files"

BASE_PATH="$1"
TYPE="$2" # f=file, d=directory
PATTERN="$3"
LABEL="${4:-$PATTERN in $BASE_PATH}"

if [ ! -d "$BASE_PATH" ]; then
    echo "  * $LABEL: base path not found"
    exit 0
fi

# Check if any matches exist
MATCHES=$(find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" 2> /dev/null | wc -l | tr -d ' ')

if [ "$MATCHES" -eq 0 ]; then
    echo "  * $LABEL: nothing to clean"
    exit 0
fi

# Delete matches with sudo directly
if [ "$TYPE" = "d" ]; then
ERROR_OUTPUT=$(sudo find "$BASE_PATH" -type d -name "$PATTERN" -exec rm -rf {} \; 2>&1)
else
ERROR_OUTPUT=$(sudo find "$BASE_PATH" -type "$TYPE" -name "$PATTERN" -delete 2>&1)
fi

if [ $? -eq 0 ]; then
echo "  * $LABEL: cleaned ($MATCHES items)"
else
    echo "  * $LABEL: ERROR - failed to clean. $ERROR_OUTPUT"
fi
