#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/projects/dotfiles"
HAMMERSPOON_AGENTS="$DOTFILES_ROOT/hammerspoon/AGENTS.md"
SPOONS_DIR="$DOTFILES_ROOT/hammerspoon/Spoons"
TEMP_FILE=$(mktemp)

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

# Replace original file
mv "${HAMMERSPOON_AGENTS}.tmp" "$HAMMERSPOON_AGENTS"
rm -f "$TEMP_FILE"

# Stage the changes (from git root)
cd "$DOTFILES_ROOT"
git add hammerspoon/AGENTS.md
