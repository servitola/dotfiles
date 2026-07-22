#!/bin/zsh
# broken_links.sh — report dangling symlinks.

_BL_PRUNE_NAMES=(node_modules .git .Trash .cache .npm dosdevices)
_BL_PRUNE_PATHS=("$HOME/Library" "$HOME/OrbStack" "*/etc/ssl/certs")

report_broken_links() {
    print_task "Scanning for broken (dangling) symlinks"

    local -a broken
    broken=()
    local link

    local -a prune_args
    prune_args=( '(' )
    local p n
    for p in "${_BL_PRUNE_PATHS[@]}"; do
        prune_args+=( -path "$p" -o )
    done
    for n in "${_BL_PRUNE_NAMES[@]}"; do
        prune_args+=( -name "$n" -o )
    done
    prune_args[-1]=')'
    while IFS= read -r link; do
        [ -n "$link" ] && broken+=("$link")
    done < <(find "$HOME" "${prune_args[@]}" -prune -o -type l ! -exec test -e {} \; -print 2>/dev/null)

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

    spinner_stop_error "Broken symlinks: $count found"

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
    done

    return 0
}
