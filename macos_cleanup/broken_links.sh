#!/bin/zsh
# broken_links.sh — report (and optionally prune) dangling symlinks.
#
# "Broken hardlinks" are not a thing: a hardlink is a second name for the same
# inode, so the data stays alive as long as any name points to it — a hardlink
# can never dangle. Only SYMLINKS can break, when their target is deleted or
# renamed. Typical cause here: an app was removed but left a symlink behind, or
# a file in ~/projects/dotfiles got renamed and old links now point at nothing.
#
# Default: report only (visibility). Set PRUNE_BROKEN_LINKS=true to `rm` them —
# a dangling symlink does nothing useful, so removal is safe junk cleanup.

# Dirs pruned from the $HOME scan: Library is full of expected app-internal
# dangling links (pure noise); the rest are heavy and never hold dotfiles links.
_BL_PRUNE_NAMES=(node_modules .git .Trash .cache .npm)
_BL_PRUNE_PATHS=("$HOME/Library")

report_broken_links() {
    print_task "Scanning for broken (dangling) symlinks"

    local prune_on_prune="false"
    [ "${PRUNE_BROKEN_LINKS:-}" = "true" ] && prune_on_prune="true"

    spinner_start "Walking \$HOME, /opt/homebrew, /usr/local"

    local -a broken
    broken=()
    local link

    # --- $HOME (pruned): build the `\( -path A -o -name B -o ... \)` group ---
    local -a prune_args
    prune_args=( '(' )
    local p n
    for p in "${_BL_PRUNE_PATHS[@]}"; do
        prune_args+=( -path "$p" -o )
    done
    for n in "${_BL_PRUNE_NAMES[@]}"; do
        prune_args+=( -name "$n" -o )
    done
    prune_args[-1]=')'   # replace trailing -o with the closing paren
    while IFS= read -r link; do
        [ -n "$link" ] && broken+=("$link")
    done < <(find "$HOME" "${prune_args[@]}" -prune -o -type l ! -exec test -e {} \; -print 2>/dev/null)

    # --- system bin dirs (small, no prune needed) ---
    local root
    for root in /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/etc /usr/local/bin; do
        [ -d "$root" ] || continue
        while IFS= read -r link; do
            [ -n "$link" ] && broken+=("$link")
        done < <(find "$root" -type l ! -exec test -e {} \; -print 2>/dev/null)
    done

    local count=${#broken[@]}

    if [ "$count" -eq 0 ]; then
        spinner_stop "Broken symlinks: none found"
        return 0
    fi

    if [ "$prune_on_prune" = "true" ]; then
        spinner_stop_error "Broken symlinks: $count found — removing (PRUNE_BROKEN_LINKS=true)"
    else
        spinner_stop_error "Broken symlinks: $count found (report only — set PRUNE_BROKEN_LINKS=true to remove)"
    fi

    local DOTFILES="$HOME/projects/dotfiles"
    local target disp tag
    for link in "${broken[@]}"; do
        target=$(readlink "$link" 2>/dev/null)
        disp="${link/#$HOME/~}"
        tag=""
        case "$target" in
            "$DOTFILES"/*|"$HOME/projects/dotfiles"/*) tag=" ${_S_BOLD}[dotfiles]${_S_NC}" ;;
        esac
        printf "  ${_S_YELLOW}↪${_S_NC} %s ${_S_DIM}→ %s${_S_NC}%b\n" "$disp" "$target" "$tag"
        if [ "$prune_on_prune" = "true" ]; then
            if "$RM_CMD" -f "$link" 2>/dev/null; then
                printf "    ${_S_GREEN}* removed${_S_NC}\n"
            else
                printf "    ${_S_YELLOW}* could not remove (permission?)${_S_NC}\n"
            fi
        fi
    done

    return 0
}
