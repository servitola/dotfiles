#!/usr/bin/env bash
# Migrate Addictive Drums 2 sample library from internal SSD to external SanDisk.
#
# After migration, samples live on the external drive and are symlinked back to
# the original location. Plug SanDisk in before launching Addictive Drums 2 (or
# any DAW that loads it as plugin).
#
# Idempotent: safe to re-run; detects already-migrated state and exits.

set -euo pipefail

EXTERNAL="/Volumes/SanDisk"
EXTERNAL_BASE="$EXTERNAL/symlinks_from_macos_home"
SUBDIR="addictive_drums_2"
EXTERNAL_TARGET="$EXTERNAL_BASE/$SUBDIR/Sound Data"

LOCAL_DIR="/Library/Application Support/XLN Audio/Addictive Drums 2"
LOCAL_TARGET="$LOCAL_DIR/Sound Data"

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_COPY="$EXTERNAL_BASE/$SUBDIR/$(basename "$SCRIPT_PATH")"

red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

# Step 1: verify external drive mounted
if [ ! -d "$EXTERNAL" ]; then
    red "External drive not mounted at $EXTERNAL. Plug SanDisk in first."
    exit 1
fi
green "External mounted at $EXTERNAL"

# Step 2: detect already-migrated state
if [ -L "$LOCAL_TARGET" ]; then
    link_target=$(readlink "$LOCAL_TARGET")
    if [ "$link_target" = "$EXTERNAL_TARGET" ]; then
        green "Already migrated. Symlink: $LOCAL_TARGET -> $link_target"
        exit 0
    else
        red "Symlink exists but points elsewhere: $link_target"
        red "Aborting to avoid clobber."
        exit 1
    fi
fi

# Step 3: verify source exists and is a real directory
if [ ! -d "$LOCAL_TARGET" ]; then
    red "Source not found: $LOCAL_TARGET"
    exit 1
fi

# Step 4: verify external has enough space
needed_kb=$(du -sk "$LOCAL_TARGET" | awk '{print $1}')
avail_kb=$(df -k "$EXTERNAL" | awk 'NR==2 {print $4}')
if [ "$avail_kb" -lt "$needed_kb" ]; then
    red "Not enough space on $EXTERNAL: need ${needed_kb} KB, available ${avail_kb} KB"
    exit 1
fi
green "Space check OK: need $((needed_kb / 1024)) MB, available $((avail_kb / 1024)) MB"

# Step 5: confirm with user
yellow "About to move $LOCAL_TARGET -> $EXTERNAL_TARGET"
yellow "Close Addictive Drums 2, Ableton, and any DAW using AD2 plugin BEFORE proceeding."
read -r -p "Proceed? [y/N] " ans
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { yellow "Aborted."; exit 0; }

# Step 6: create external target dir
mkdir -p "$EXTERNAL_BASE/$SUBDIR"

# Step 7: move data (requires sudo because /Library/Application Support is root-owned)
green "Moving samples to external (this may take a few minutes for ~11 GB)..."
sudo mv "$LOCAL_TARGET" "$EXTERNAL_TARGET"

# Step 8: create symlink at original location
green "Creating symlink..."
sudo ln -s "$EXTERNAL_TARGET" "$LOCAL_TARGET"

# Step 9: copy this script to external for reference
cp "$SCRIPT_PATH" "$SCRIPT_COPY" && green "Script copied to $SCRIPT_COPY"

# Step 10: verify
green "Done. Verification:"
ls -la "$LOCAL_TARGET"
echo
green "On disk freed: $((needed_kb / 1024)) MB"
green "Remember: SanDisk must be plugged in before opening AD2 / Ableton."
