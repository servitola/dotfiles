#!/bin/zsh
setopt no_unset pipe_fail

source "${0:a:h}/targets.sh"

COMPRESS_MIN_RATIO=0.9   # at applesauce's 0.95 the xattr overhead makes marginal files net larger

GREEN=$'\e[0;92m' YELLOW=$'\e[0;33m' BLUE=$'\e[0;94m' BOLD=$'\e[1m' NC=$'\e[0m'

_reclaimed=0 _touched=0 _blocked=0 _shown=0

# Silent when nothing changed: the heading appears with the first line worth printing.
_header() { (( _shown++ )) || printf "\n${BLUE}${BOLD}━━━ Static Data Compression (APFS/LZFSE) ━━━${NC}\n" }
_row()  { _header; printf "  %-36s %7.2f GB  %b\n" "$1" "$(( $2 / 1e9 ))" "$3" }
_warn() { _header; printf "  ${YELLOW}⚠ %-34s %s${NC}\n" "$1" "$2"; attention "compression of $1: $2" }
attention() { print -r -- "$*" >> "${UP_ATTENTION:-/dev/null}" }

_compress() {
    local target=$1 label=$2 out lg before after new
    out=$(applesauce compress -c lzfse -r "$COMPRESS_MIN_RATIO" "$target" 2>&1) \
        || { _warn "$label" "applesauce failed"; print -r -- "$out"; return }
    read -r lg before after new <<<"$(print -r -- "$out" | awk -F'[()]' '
        /^New Files Compressed:/            { split($1, w, " "); n = w[4] }
        /^Starting Size \(total filesize\)/ { l = $4 }
        /^Starting Size \(on disk\)/        { b = $4 }
        /^Final Size \(on disk\)/           { f = $4 }
        END { print l, b, f, n }')"
    [[ -n $lg && -n $before && -n $after && -n $new ]] \
        || { _warn "$label" "unreadable applesauce output"; return }

    (( new )) || return
    (( _reclaimed += before - after, ++_touched ))
    _row "$label" "$after" "${GREEN}compressed $new new files, −$(printf '%.2f' $(( (before - after) / 1e9 ))) GB${NC}"
}

for target in "${COMPRESS_TARGETS[@]}"; do
    [[ -d $target ]] || continue
    label=${${target/#$HOME/\~}/\/Library\/Application Support\//\/…\/}
    _compress "$target" "$label"
done

for app in "${COMPRESS_APPS[@]}"; do
    [[ -d $app ]] || continue

    # rewriting a bundle whose executable is mmap'd can SIGBUS the running app
    if pgrep -f "$app/Contents/" >/dev/null 2>&1; then
        continue
    # without App Management applesauce reports a cheerful 0% and changes nothing
    elif [[ ! -w "$app/Contents/Info.plist" ]]; then
        (( ++_blocked ))
    else
        _compress "$app" "${app:t}"
    fi
done

(( _blocked )) && _warn "$_blocked apps" "no write access: System Settings → Privacy & Security → App Management → this terminal"

if (( _touched )); then
    printf "  ${GREEN}${BOLD}✓ reclaimed %.2f GB${NC} in %d apps and folders\n" "$(( _reclaimed / 1e9 ))" "$_touched"
fi
