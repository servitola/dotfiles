#!/bin/bash
# Pre-commit: every AGENTS.md must have sibling CLAUDE.md and WARP.md symlinks
# pointing at it, so Claude Code / Warp pick up the same per-directory guide.
#
# Receives staged filenames from pre-commit. For each staged AGENTS.md whose
# sibling symlink is missing or wrong, it creates the symlink AND `git add`s it,
# so the link lands in the same commit (a pre-commit hook that only touched the
# worktree would leave the symlink uncommitted).
set -euo pipefail

made=0
for f in "$@"; do
    case "$(basename "$f")" in
        AGENTS.md) ;;
        *) continue ;;
    esac
    [ -f "$f" ] || continue          # deleted/renamed — nothing to link
    dir="$(dirname "$f")"
    for sib in CLAUDE.md WARP.md; do
        link="$dir/$sib"
        if [ ! -L "$link" ] || [ "$(readlink "$link")" != "AGENTS.md" ]; then
            ln -sfh "AGENTS.md" "$link"
            git add "$link"
            echo "ensure-agents-symlinks: linked $link -> AGENTS.md"
            made=1
        fi
    done
done

# Auto-fixed and staged in place — never block the commit.
exit 0
