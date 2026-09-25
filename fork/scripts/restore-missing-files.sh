#!/usr/bin/env bash
# Case-only dedup commits (Dresses DO-908) unlink the lowercase twin on case-insensitive APFS,
# leaving tracked files deleted on disk. Restore them from the index.
source "$HOME/projects/dotfiles/fork/scripts/lib.sh"

waitlock
missing=()
while IFS= read -r -d '' f; do missing+=("$f"); done < <(git ls-files -z -d)

if [ "${#missing[@]}" -eq 0 ]; then
  notify "Nothing to restore"
  exit 0
fi

out=$(git checkout -- "${missing[@]}" 2>&1) || {
  alert "Fork: restore failed" "$out"
  exit 1
}
notify "Restored ${#missing[@]} file(s)"
