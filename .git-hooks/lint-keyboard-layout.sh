#!/bin/bash
# Pre-commit lint for hammerspoon/Spoons/HotKeys.spoon/layout/60%/*.lua.
# Validates canonical ASCII format and coverage; passes on warnings.
# Filenames passed by pre-commit; we only check format (--strict, no drift)
# so the hook is fast and runs without parsing karabiner.json / keylayouts.
set -e

# Repo root from git so the hook also works on CI runners (pre-commit
# always runs hooks from the repository root).
DOTFILES_ROOT="$(git rev-parse --show-toplevel)"

# Filter to only *.lua files inside layout/60%/
files=()
for f in "$@"; do
    case "$f" in
        hammerspoon/Spoons/HotKeys.spoon/layout/60%/*.lua)
            files+=("$(basename "$f")")
            ;;
    esac
done

# Nothing to check
[ ${#files[@]} -eq 0 ] && exit 0

# Strict mode: only ERROR fails the hook (format + coverage)
# Skip drift checks to avoid karabiner.json/keylayout parse overhead
python3 "$DOTFILES_ROOT/docs/keyboard/tools/lint.py" \
    --strict --skip-drift --files "${files[@]}"
