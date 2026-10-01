#!/bin/zsh
# Step 18 — third-party Hammerspoon Spoons, installed from their GitHub releases
source "${0:a:h}/lib.sh"
set -euo pipefail

SPOONS="$DOTFILES/hammerspoon/Spoons"
BIRMAN_LAYER=v3.9.1   # https://github.com/servitola/BirmanLayer.spoon/releases
POWER_WINDOWS=v0.2.0  # https://github.com/servitola/PowerWindows.spoon/releases
SCREEN_GLOW=v0.1.0    # https://github.com/servitola/ScreenGlow.spoon/releases
FRESH_4K_WALLPAPER=v0.2.0  # https://github.com/servitola/Fresh4kWallpaper.spoon/releases
AUTO_KEYBOARD_LAYOUT=v0.1.0  # https://github.com/servitola/AutoKeyboardLayout.spoon/releases

install_spoon() {  # <name> <owner/repo> <tag>
    local name=$1 repo=$2 tag=$3 tmp
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/$name.spoon.zip" \
        "https://github.com/$repo/releases/download/$tag/$name.spoon.zip"
    rm -rf "$SPOONS/$name.spoon"
    unzip -q "$tmp/$name.spoon.zip" -d "$SPOONS"
    rm -rf "$tmp"
    echo "$name.spoon $tag"
}

section "Hammerspoon Spoons from GitHub releases"
install_spoon BirmanLayer servitola/BirmanLayer.spoon "$BIRMAN_LAYER"
install_spoon PowerWindows servitola/PowerWindows.spoon "$POWER_WINDOWS"
install_spoon ScreenGlow servitola/ScreenGlow.spoon "$SCREEN_GLOW"
install_spoon Fresh4kWallpaper servitola/Fresh4kWallpaper.spoon "$FRESH_4K_WALLPAPER"
install_spoon AutoKeyboardLayout servitola/AutoKeyboardLayout.spoon "$AUTO_KEYBOARD_LAYOUT"
