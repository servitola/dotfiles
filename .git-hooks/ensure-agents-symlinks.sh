#!/bin/bash
# Every AGENTS.md must have a sibling CLAUDE.md symlink
# pointing at it

set -euo pipefail

for f in "$@"; do
    case "$(basename "$f")" in
        AGENTS.md) ;;
        *) continue ;;
    esac
    [ -f "$f" ] || continue          # deleted/renamed — nothing to link
    dir="$(dirname "$f")"
    link="$dir/CLAUDE.md"
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

exit 0
