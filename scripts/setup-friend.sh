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
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!!]${NC} $1"; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; exit 1; }
step()  { echo -e "\n${CYAN}${BOLD}>>> $1${NC}"; }

# --- Sanity checks ---
[[ "$(uname)" == "Darwin" ]] || fail "This script only works on macOS."

# --- Banner ---
echo ""
echo -e "${MAGENTA}${BOLD}"
cat << 'BANNER'
      _    _     ___  _   _ _____ ____
     / \  | |   / _ \| \ | | ____|  _ \
    / _ \ | |  | | | |  \| |  _| | |_) |
   / ___ \| |__| |_| | |\  | |___|  _ <
  /_/   \_\_____\___/|_| \_|_____|_| \_\
BANNER
echo -e "${NC}"
echo -e "${DIM}  dev environment setup by servitola${NC}"
echo -e "${BOLD}  Homebrew -> Node.js -> Ampcode (+ config) -> Warp${NC}"
echo ""
sleep 1

# --- 1. Xcode Command Line Tools ---
step "Step 1/7: Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
    echo -e "  Installing... this is needed for everything else"
    xcode-select --install 2>/dev/null || true
    echo ""
    warn "A system dialog should appear. Click 'Install' and wait."
    warn "After it finishes, run this script again."
    exit 0
else
    info "Already installed"
fi

# --- 2. Homebrew ---
step "Step 2/7: Homebrew (package manager)"
if ! command -v brew &>/dev/null; then
    echo -e "  Installing the backbone of macOS dev tools..."
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
    info "Homebrew installed"
else
    info "Homebrew $(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
fi

if ! command -v brew &>/dev/null; then
    fail "brew not found after installation. Close this terminal, open a new one, and re-run the script."
fi

# --- 3. Node.js ---
step "Step 3/7: Node.js"
if ! command -v node &>/dev/null; then
    echo -e "  Installing JavaScript runtime..."
    if ! brew install node; then
        fail "Failed to install Node.js. Run 'brew doctor' and try again."
    fi
    info "Node.js $(node --version) installed"
else
    info "Node.js $(node --version)"
fi

if ! command -v npm &>/dev/null; then
    fail "npm not found. Node.js may not have installed correctly. Try: brew reinstall node"
fi

# --- 4. ampcode ---
step "Step 4/7: Ampcode (AI coding agent)"
if ! command -v amp &>/dev/null; then
    echo -e "  Installing the good stuff..."
    if ! npm install -g @sourcegraph/amp; then
        fail "Failed to install ampcode. Try manually: npm install -g @sourcegraph/amp"
    fi
    info "Ampcode installed"
else
    info "Ampcode $(amp --version 2>/dev/null || echo 'ready')"
fi

# --- 5. ampcode settings ---
step "Step 5/7: Ampcode settings"
AMP_CONFIG_DIR="$HOME/.config/amp"
AMP_SETTINGS="$AMP_CONFIG_DIR/settings.json"
AMP_SETTINGS_URL="https://raw.githubusercontent.com/servitola/dotfiles/spotware/amp/settings.json"

mkdir -p "$AMP_CONFIG_DIR"
if [[ -f "$AMP_SETTINGS" ]]; then
    info "Settings already exist at $AMP_SETTINGS"
    warn "To overwrite, delete the file and re-run the script"
else
    echo -e "  Downloading pre-configured settings..."
    if ! curl -fsSL "$AMP_SETTINGS_URL" -o "$AMP_SETTINGS"; then
        fail "Failed to download ampcode settings. Check your internet connection."
    fi
    info "Settings saved to $AMP_SETTINGS"
fi

# --- 6. Global AI profile ---
step "Step 6/7: Global AI profile (AGENTS.md)"
AMP_AGENTS_MD="$AMP_CONFIG_DIR/AGENTS.md"

if [[ -f "$AMP_AGENTS_MD" ]]; then
    info "AGENTS.md already exists"
    warn "To overwrite, delete $AMP_AGENTS_MD and re-run"
else
    echo -e "  Creating your AI assistant profile..."
    cat > "$AMP_AGENTS_MD" << 'AGENTSMD'
# Global Instructions

## About the user

- Name: Alexey (aloner)
- Role: Marketing specialist
- Technical level: intermediate — comfortable with basic terminal commands, but not a developer
- OS: macOS
- Primary language: Russian (understands English)

## Communication style

- Respond in Russian by default unless the user writes in English
- Explain technical concepts in simple terms, avoid unnecessary jargon
- When suggesting terminal commands, briefly explain what each command does
- If a task involves risk (deleting files, changing system settings), always warn before executing
- Prefer step-by-step instructions over long blocks of code

## How to help

- Be proactive: suggest solutions, not just answer questions
- When the user asks "how to do X", give a ready-to-use solution, not just theory
- For file operations, always confirm paths before modifying
- If unsure about user's intent, ask a clarifying question instead of guessing
- Help with: marketing automation, data analysis, text processing, file management, web scraping, spreadsheets

## Environment

- Shell: zsh (default macOS)
- Terminal: Warp
- Package manager: Homebrew
- No development environment pre-configured — install tools as needed
AGENTSMD
    info "Profile created at $AMP_AGENTS_MD"
fi

# --- 7. Warp Terminal ---
step "Step 7/7: Warp Terminal"
if [[ -d "/Applications/Warp.app" ]]; then
    info "Warp is already installed"
else
    echo -e "  Downloading the best terminal on the planet..."
    WARP_DMG="/tmp/Warp.dmg"

    if ! curl -fSL "https://releases.warp.dev/stable/v0.2025.01.01.00.00.stable_00/Warp.dmg" -o "$WARP_DMG" 2>/dev/null; then
        if ! curl -fSL "https://app.warp.dev/download?package=dmg" -o "$WARP_DMG"; then
            fail "Failed to download Warp. Download manually: https://www.warp.dev/download"
        fi
    fi

    echo -e "  Opening installer..."
    if ! hdiutil attach "$WARP_DMG" -quiet; then
        fail "Failed to mount Warp.dmg. Open it manually: open /tmp/Warp.dmg"
    fi
    open /Volumes/Warp*/ 2>/dev/null || true
    info "Drag Warp to Applications folder"
fi

# --- Summary ---
echo ""
echo -e "${GREEN}${BOLD}"
cat << 'DONE'
   ____   ___  _   _ _____
  |  _ \ / _ \| \ | | ____|
  | | | | | | |  \| |  _|
  | |_| | |_| | |\  | |___
  |____/ \___/|_| \_|_____|
DONE
echo -e "${NC}"
echo -e "  ${BOLD}aloner, you're all set:${NC}"
echo ""
command -v brew &>/dev/null && echo -e "  ${GREEN}*${NC} Homebrew $(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
command -v node &>/dev/null && echo -e "  ${GREEN}*${NC} Node.js $(node --version 2>/dev/null)"
command -v amp  &>/dev/null && echo -e "  ${GREEN}*${NC} Ampcode $(amp --version 2>/dev/null || echo '')"
[[ -f "$HOME/.config/amp/settings.json" ]] && echo -e "  ${GREEN}*${NC} Ampcode settings configured"
[[ -f "$HOME/.config/amp/AGENTS.md" ]] && echo -e "  ${GREEN}*${NC} AI profile (AGENTS.md)"
if [[ -d "/Applications/Warp.app" ]]; then
    echo -e "  ${GREEN}*${NC} Warp Terminal"
else
    echo -e "  ${YELLOW}*${NC} Warp Terminal — drag to Applications and launch"
fi
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "  ${BOLD}1.${NC} Open Warp"
echo -e "  ${BOLD}2.${NC} Run ${BOLD}amp login${NC} to authenticate"
echo -e "  ${BOLD}3.${NC} Go to any project folder and type ${BOLD}amp${NC}"
echo ""
