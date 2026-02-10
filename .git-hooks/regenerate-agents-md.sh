#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/projects/dotfiles"
AGENTS_MD="$DOTFILES_ROOT/AGENTS.md"
TEMP_FILE=$(mktemp)
BACKUP_FILE="${AGENTS_MD}.bak.$$"

# Safety: create backup before modifying
cp "$AGENTS_MD" "$BACKUP_FILE"

# Generate directory tree (without summary line)
cd "$DOTFILES_ROOT"
LC_COLLATE=C tree -L 2 -I '.git|.DS_Store|node_modules|ableton' --dirsfirst --noreport >"$TEMP_FILE"

# Extract content before the marker
awk '/^## Current Directory Structure \(depth 2\)$/{exit} {print}' "$AGENTS_MD" >"${AGENTS_MD}.tmp"

# Add the new section
echo "## Current Directory Structure (depth 2)" >>"${AGENTS_MD}.tmp"
cat "$TEMP_FILE" >>"${AGENTS_MD}.tmp"
echo "Finish of Directory Structure" >>"${AGENTS_MD}.tmp"

# Extract content after the marker (if any)
awk '/^Finish of Directory Structure$/{flag=1; next} flag' "$AGENTS_MD" >>"${AGENTS_MD}.tmp"

# Verify the new file isn't empty and has reasonable size
if [ ! -s "${AGENTS_MD}.tmp" ] || [ $(wc -l < "${AGENTS_MD}.tmp") -lt 10 ]; then
    echo "ERROR: regenerate-agents-md.sh produced invalid output. Restoring from backup." >&2
    cp "$BACKUP_FILE" "$AGENTS_MD"
    rm -f "$BACKUP_FILE" "$TEMP_FILE" "${AGENTS_MD}.tmp"
    exit 1
fi

# Replace original file only if new file is valid
mv "${AGENTS_MD}.tmp" "$AGENTS_MD"
rm -f "$BACKUP_FILE" "$TEMP_FILE"

# Stage only this file's changes
git add AGENTS.md
