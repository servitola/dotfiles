#!/bin/zsh
# Late on purpose: needs Homebrew's python and the apps it configures.
source "${0:a:h}/lib.sh"
set -euo pipefail

if [[ -n "${CI:-}" ]]; then
    section "CI: skip machine shortcuts (this machine's hotkeys, not a runner's)"
    exit 0
fi

section "Shortcuts: system, app and menu (macos_shortcuts/shortcuts.toml)"
# A fresh Mac may still be on Apple's python 3.9, which has no tomllib.
if ! python3 -c 'import tomllib' 2>/dev/null; then
    echo "skipped: python3 lacks tomllib (need >= 3.11) — brew install python@3.13, then:"
    echo "  python3 $DOTFILES/macos_shortcuts/shortcuts.py apply"
    exit 0
fi
python3 "$DOTFILES/macos_shortcuts/shortcuts.py" apply
