#!/usr/bin/env bash
# Merge the checked-out branch INTO the branch selected in Fork, without leaving
# the current branch. The merge is built with `git merge-tree --write-tree`, so
# the working tree and index are never touched (fast on big repos, no index.lock
# fight with Fork). Always creates a merge commit (--no-ff semantics).
. "$(dirname "$0")/lib.sh"
target="$1"
repo="$2"
cd "$repo" || exit 1

current=$(git rev-parse --abbrev-ref HEAD)
[ "$current" = HEAD ] && { alert "Fork: detached HEAD" "Check out a branch first."; exit 1; }
[ "$current" = "$target" ] && { alert "Fork: same branch" "You are already on $target."; exit 1; }
cur_sha=$(git rev-parse --verify "refs/heads/$current") || exit 1
tgt_sha=$(git rev-parse --verify "refs/heads/$target") || { alert "Fork: no such branch" "Local branch $target not found."; exit 1; }
if git merge-base --is-ancestor "$cur_sha" "$tgt_sha"; then
  notify "$target already contains $current"
  exit 0
fi

# If the target is checked out in another worktree, moving its ref underneath
# would desync that worktree — merge there instead (only when it is clean).
wt=$(git worktree list --porcelain | awk -v b="branch refs/heads/$target" '/^worktree /{w=substr($0,10)} $0==b{print w}')
if [ -n "$wt" ]; then
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then
    alert "Fork: worktree dirty" "$target is checked out in $wt with uncommitted changes. Commit or stash them there first."
    exit 1
  fi
  out=$(git -C "$wt" merge --no-ff --no-edit "$current" 2>&1) || {
    git -C "$wt" merge --abort >/dev/null 2>&1
    alert "Fork: merge conflict" "Merging $current into $target (worktree $wt) hit a conflict. Aborted — nothing changed.

$out"
    exit 1
  }
  notify "Merged $current into $target (worktree $wt)"
  exit 0
fi

out=$(git merge-tree --write-tree --name-only "$tgt_sha" "$cur_sha" 2>&1)
rc=$?
if [ "$rc" -eq 1 ]; then
  alert "Fork: merge conflict" "Cannot merge $current into $target — conflicts in:
$(printf '%s\n' "$out" | tail -n +2 | sed '/^$/q' | sed '/^$/d')

Nothing changed."
  exit 1
fi
if [ "$rc" -ne 0 ]; then
  alert "Fork: merge failed" "$out"
  exit 1
fi
tree=$(printf '%s\n' "$out" | head -1)
commit=$(git commit-tree "$tree" -p "$tgt_sha" -p "$cur_sha" -m "Merge branch '$current' into $target") || {
  alert "Fork: merge failed" "Could not create the merge commit."
  exit 1
}
git update-ref -m "merge $current: Merge made by Fork" "refs/heads/$target" "$commit" "$tgt_sha" || {
  alert "Fork: merge failed" "Could not update $target (did it move meanwhile?)."
  exit 1
}
notify "Merged $current into $target"
exit 0
