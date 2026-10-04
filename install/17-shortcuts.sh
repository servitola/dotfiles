#!/bin/zsh
# Step 17 — system, app and menu shortcuts from macos/shortcuts.toml. Runs late:
# it needs Homebrew's python (tomllib) and the sandboxed apps already installed.
source "${0:a:h}/lib.sh"
set -euo pipefail

if [[ -n "${CI:-}" ]]; then
    section "CI: skip machine shortcuts (this machine's hotkeys, not a runner's)"
    exit 0
fi

section "Shortcuts: system, app and menu (macos/shortcuts.toml)"
# tomllib needs python >= 3.11; minimum_brewfile does not install one, so a fresh
# Mac may still be on Apple's 3.9 here. Skipping beats aborting the last step.
if ! python3 -c 'import tomllib' 2>/dev/null; then
    echo "skipped: python3 lacks tomllib (need >= 3.11) — brew install python@3.13, then:"
    echo "  python3 $DOTFILES/docs/keyboard/tools/shortcuts.py apply"
    exit 0
fi
python3 "$DOTFILES/docs/keyboard/tools/shortcuts.py" apply
