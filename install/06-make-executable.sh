#!/bin/zsh
# A script is a tracked file that starts with #!; sourced fragments have none and stay plain.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "chmod +x every tracked script (detected by #! shebang)"
count=0
# NB: loop var must NOT be named `path` — in zsh $path is tied to $PATH.
while IFS= read -r -d '' rel; do
    file="$DOTFILES/$rel"
    [[ -L $file || ! -f $file ]] && continue
    IFS= read -r shebang < "$file" 2>/dev/null || true   # a one-line file without a newline still counts
    [[ ${shebang:-} == '#!'* ]] || continue
    chmod +x "$file"
    count=$(( count + 1 ))   # not (( count++ )): it returns 1 for zero and set -e would stop
done < <(git -C "$DOTFILES" ls-files -z)
log "$count scripts executable"
