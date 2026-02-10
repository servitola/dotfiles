#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/projects/dotfiles"

# Find AGENTS.md in first-level directories and create CLAUDE.md and WARP.md symlinks
find "$DOTFILES_ROOT" -maxdepth 4 -name "AGENTS.md" -type f ! -path "*/.git/*" -print0 2>/dev/null | while IFS= read -r -d '' agents_file; do
    # Only process AGENTS.md files that are in first-level, root, or nested app directories (depth 0, 1, or 2)
    parent_dir=$(dirname "$agents_file")
    depth=$(($(echo "$parent_dir" | grep -o "/" | wc -l) - $(echo "$DOTFILES_ROOT" | grep -o "/" | wc -l)))

    # Process root (depth 0), first-level (depth 1), and nested directories like Spoons (depth 2-3)
    if [[ $depth -le 3 ]]; then
        # Create CLAUDE.md symlink pointing to AGENTS.md
        claude_file="$parent_dir/CLAUDE.md"
        if [[ ! -L "$claude_file" ]] || [[ $(readlink "$claude_file") != "AGENTS.md" ]]; then
            ln -sfvh "AGENTS.md" "$claude_file" 2>/dev/null || true
        fi

        # Create WARP.md symlink pointing to AGENTS.md
        warp_file="$parent_dir/WARP.md"
        if [[ ! -L "$warp_file" ]] || [[ $(readlink "$warp_file") != "AGENTS.md" ]]; then
            ln -sfvh "AGENTS.md" "$warp_file" 2>/dev/null || true
        fi
    fi
done
