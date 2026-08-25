#!/bin/zsh
# decmpfs is dropped on every write, so each SDK update silently un-compresses
# what it touched — hence on every `up`. Details: applesauce/AGENTS.md.
setopt no_unset pipe_fail

source "${0:a:h}/targets.sh"

COMPRESS_MIN_RATIO=0.9   # at applesauce's 0.95 the xattr overhead makes marginal files net larger

GREEN=$'\e[0;92m' YELLOW=$'\e[0;33m' DIM=$'\e[2m' BOLD=$'\e[1m' NC=$'\e[0m'

_logical=0 _on_disk=0 _reclaimed=0 _touched=0 _blocked=0

_row()  { printf "  %-36s %7.2f GB  %b\n" "$1" "$(( $2 / 1e9 ))" "$3" }
_warn() { printf "  ${YELLOW}⚠ %-34s %s${NC}\n" "$1" "$2" }

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

    (( _logical += lg, _on_disk += after, _reclaimed += before - after ))
    (( new )) || { _row "$label" "$after" "${DIM}already compressed${NC}"; return }
    (( ++_touched ))
    _row "$label" "$after" "${GREEN}compressed $new new files, −$(printf '%.2f' $(( (before - after) / 1e9 ))) GB${NC}"
}

_report() {
    local target=$1 label=$2 note=$3 out lg on_disk
    out=$(applesauce info "$target" 2>&1) && read -r lg on_disk <<<"$(print -r -- "$out" | awk -F'[()]' '
        /^Total uncompressed size:/ { l = $2 }
        /^Total compressed size:/   { d = $2 }
        END { print l, d }')"
    [[ -n ${lg:-} && -n ${on_disk:-} ]] || { printf "  %-36s %10s  %b\n" "$label" "?" "$note"; return }
    (( _logical += lg, _on_disk += on_disk ))
    _row "$label" "$on_disk" "$note"
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
        _report "$app" "${app:t}" "${DIM}running — quit it to refresh${NC}"
    # without App Management applesauce reports a cheerful 0% and changes nothing
    elif [[ ! -w "$app/Contents/Info.plist" ]]; then
        (( ++_blocked ))
        _report "$app" "${app:t}" "${YELLOW}no write access${NC}"
    else
        _compress "$app" "${app:t}"
    fi
done

(( _blocked )) && printf "\n  ${YELLOW}⚠ %d apps cannot be re-compressed after their next update${NC}\n    ${DIM}System Settings → Privacy & Security → App Management → this terminal${NC}\n" "$_blocked"

if (( _touched )); then
    printf "\n  ${GREEN}${BOLD}✓ reclaimed %.2f GB${NC} in %d of %d targets — " \
        "$(( _reclaimed / 1e9 ))" "$_touched" "$(( $#COMPRESS_TARGETS + $#COMPRESS_APPS ))"
else
    printf "\n  ${GREEN}✓ nothing to do${NC} — "
fi
printf "%.1f GB of data now fits in %.1f GB on disk\n" "$(( _logical / 1e9 ))" "$(( _on_disk / 1e9 ))"
