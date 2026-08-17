#!/bin/bash
# Every AGENTS.md must have sibling CLAUDE.md and WARP.md symlinks
# pointing at it

set -euo pipefail

for f in "$@"; do
    case "$(basename "$f")" in
        AGENTS.md) ;;
        *) continue ;;
    esac
    [ -f "$f" ] || continue          # deleted/renamed — nothing to link
    dir="$(dirname "$f")"
    for sib in CLAUDE.md WARP.md; do
        link="$dir/$sib"
        # Never clobber a real file (e.g. claude-code/CLAUDE.md is the global
        # Claude memory, not a per-directory guide symlink).
        if [ -e "$link" ] && [ ! -L "$link" ]; then
            echo "ensure-agents-symlinks: $link is a regular file — skipping"
            continue
        fi
        if [ ! -L "$link" ] || [ "$(readlink "$link")" != "AGENTS.md" ]; then
            ln -sfh "AGENTS.md" "$link"
            git add "$link"
            echo "ensure-agents-symlinks: linked $link -> AGENTS.md"
        fi
    done
done

# Auto-fixed and staged in place — never block the commit.
exit 0
