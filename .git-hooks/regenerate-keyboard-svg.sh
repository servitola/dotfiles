#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/projects/dotfiles"

python3 "$DOTFILES_ROOT/docs/keyboard/generate.py"

cd "$DOTFILES_ROOT"
git add docs/keyboard/*.svg
