#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/projects/dotfiles"
HAMMERSPOON_AGENTS="$DOTFILES_ROOT/hammerspoon/AGENTS.md"
SPOONS_DIR="$DOTFILES_ROOT/hammerspoon/Spoons"
TEMP_FILE=$(mktemp)
BACKUP_FILE=$(mktemp)

# Safety: create backup in temp location (not visible)
cp "$HAMMERSPOON_AGENTS" "$BACKUP_FILE"

# Generate list of Spoons
cd "$SPOONS_DIR"
ls -1d *.spoon 2>/dev/null | sed 's/.spoon$//' | sort > "$TEMP_FILE"

# Extract content before the marker
awk '/^## Installed Spoons$/{exit} {print}' "$HAMMERSPOON_AGENTS" > "${HAMMERSPOON_AGENTS}.tmp"

# Add the new section
echo "## Installed Spoons" >> "${HAMMERSPOON_AGENTS}.tmp"
while IFS= read -r spoon; do
    echo "- $spoon" >> "${HAMMERSPOON_AGENTS}.tmp"
done < "$TEMP_FILE"
echo "" >> "${HAMMERSPOON_AGENTS}.tmp"

# Extract content after the marker (if any)
awk '/^## Critical Rules$/{flag=1} flag' "$HAMMERSPOON_AGENTS" >> "${HAMMERSPOON_AGENTS}.tmp"

# Verify the new file isn't empty and has reasonable size
if [ ! -s "${HAMMERSPOON_AGENTS}.tmp" ] || [ $(wc -l < "${HAMMERSPOON_AGENTS}.tmp") -lt 5 ]; then
    echo "ERROR: regenerate-hammerspoon-spoons.sh produced invalid output. Restoring from backup." >&2
    cp "$BACKUP_FILE" "$HAMMERSPOON_AGENTS"
    rm -f "$BACKUP_FILE" "$TEMP_FILE" "${HAMMERSPOON_AGENTS}.tmp"
    exit 1
fi

# Replace original file only if new file is valid
mv "${HAMMERSPOON_AGENTS}.tmp" "$HAMMERSPOON_AGENTS"
rm -f "$BACKUP_FILE" "$TEMP_FILE"

# Stage the changes (from git root)
cd "$DOTFILES_ROOT"
git add hammerspoon/AGENTS.md
