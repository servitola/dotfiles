#!/bin/zsh
# Step 06 — make every script executable. A "script" is a tracked file with a
# #! shebang; sourced-only fragments (aliases.sh, exports.sh, …) have none and
# stay non-exec. New scripts just work — there's no list to maintain.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "chmod +x every tracked script (detected by #! shebang)"
count=0
# NB: loop var must NOT be named `path` — in zsh $path is tied to $PATH.
while IFS= read -r -d '' rel; do
    file="$DOTFILES/$rel"
    [[ -L $file || ! -f $file ]] && continue      # skip symlinks / deleted
    IFS= read -r shebang < "$file" 2>/dev/null || true   # no-newline file: keep going
    [[ ${shebang:-} == '#!'* ]] || continue
    chmod +x "$file"
    count=$(( count + 1 ))                        # assignment, not (( c++ )): set -e safe
done < <(git -C "$DOTFILES" ls-files -z)
log "$count scripts executable"
