#!/bin/bash
#
# Setup script: Homebrew -> Node.js -> ampcode (npm) + Warp Terminal
# Works on a fresh macOS with nothing pre-configured.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/servitola/dotfiles/spotware/scripts/setup-friend.sh)
#

set -euo pipefail

# --- Colors and helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Sanity checks ---
[[ "$(uname)" == "Darwin" ]] || fail "This script only works on macOS."

echo ""
echo "=== macOS Developer Setup ==="
echo "    Homebrew -> Node.js -> ampcode + Warp"
echo ""

# --- 1. Xcode Command Line Tools ---
if ! xcode-select -p &>/dev/null; then
    info "[1/5] Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    echo ""
    warn "A system dialog should appear. Click 'Install' and wait."
    warn "After it finishes, run this script again."
    exit 0
else
    info "[1/5] Xcode Command Line Tools — OK"
fi

# --- 2. Homebrew ---
if ! command -v brew &>/dev/null; then
    info "[2/5] Installing Homebrew..."
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        fail "Homebrew installation failed. Check your internet connection and try again."
    fi

    # Add brew to PATH for Apple Silicon and Intel
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo >> ~/.zprofile
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    info "[2/5] Homebrew — OK"
fi

if ! command -v brew &>/dev/null; then
    fail "brew not found after installation. Close this terminal, open a new one, and re-run the script."
fi

# --- 3. Node.js ---
if ! command -v node &>/dev/null; then
    info "[3/5] Installing Node.js via Homebrew..."
    if ! brew install node; then
        fail "Failed to install Node.js. Run 'brew doctor' and try again."
    fi
else
    info "[3/5] Node.js $(node --version) — OK"
fi

if ! command -v npm &>/dev/null; then
    fail "npm not found. Node.js may not have installed correctly. Try: brew reinstall node"
fi

# --- 4. ampcode ---
if ! command -v amp &>/dev/null; then
    info "[4/5] Installing ampcode..."
    if ! npm install -g @sourcegraph/amp; then
        fail "Failed to install ampcode. Try manually: npm install -g @sourcegraph/amp"
    fi
else
    info "[4/5] ampcode — OK"
fi

# --- 5. Warp Terminal ---
if [[ -d "/Applications/Warp.app" ]]; then
    info "[5/5] Warp Terminal — OK"
else
    info "[5/5] Downloading Warp Terminal..."
    WARP_DMG="/tmp/Warp.dmg"

    if ! curl -fSL "https://releases.warp.dev/stable/v0.2025.01.01.00.00.stable_00/Warp.dmg" -o "$WARP_DMG" 2>/dev/null; then
        if ! curl -fSL "https://app.warp.dev/download?package=dmg" -o "$WARP_DMG"; then
            fail "Failed to download Warp. Download manually: https://www.warp.dev/download"
        fi
    fi

    info "Opening Warp installer — drag it to Applications..."
    if ! hdiutil attach "$WARP_DMG" -quiet; then
        fail "Failed to mount Warp.dmg. Open it manually: open /tmp/Warp.dmg"
    fi
    open /Volumes/Warp*/ 2>/dev/null || true
fi

# --- Summary ---
echo ""
echo "=== Done ==="
echo ""
command -v brew    &>/dev/null && info "Homebrew $(brew --version 2>/dev/null | head -1)"
command -v node    &>/dev/null && info "Node.js $(node --version 2>/dev/null)"
command -v amp    &>/dev/null && info "ampcode $(amp --version 2>/dev/null || echo 'installed')"
if [[ -d "/Applications/Warp.app" ]]; then
    info "Warp Terminal"
else
    warn "Warp Terminal — drag from the opened disk image to Applications"
fi
echo ""
