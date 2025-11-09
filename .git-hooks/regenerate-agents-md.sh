#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/projects/dotfiles"
AGENTS_MD="$DOTFILES_ROOT/AGENTS.md"
TEMP_FILE=$(mktemp)

# Generate directory tree (without summary line)
cd "$DOTFILES_ROOT"
tree -L 2 -I '.git|.DS_Store|node_modules|ableton' --dirsfirst --noreport >"$TEMP_FILE"

# Extract content before the marker
awk '/^## Current Directory Structure \(depth 2\)$/{exit} {print}' "$AGENTS_MD" >"${AGENTS_MD}.tmp"

# Add the new section
echo "## Current Directory Structure (depth 2)" >>"${AGENTS_MD}.tmp"
cat "$TEMP_FILE" >>"${AGENTS_MD}.tmp"
echo "Finish of Directory Structure" >>"${AGENTS_MD}.tmp"

# Extract content after the marker (if any)
awk '/^Finish of Directory Structure$/{flag=1; next} flag' "$AGENTS_MD" >>"${AGENTS_MD}.tmp"

# Replace original file
mv "${AGENTS_MD}.tmp" "$AGENTS_MD"
rm -f "$TEMP_FILE"

# Stage the changes
git add AGENTS.md
