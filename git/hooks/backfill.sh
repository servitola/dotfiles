#!/usr/bin/env bash
# One-time (rerunnable) backfill: adds the commit-msg AI-footer hook to every
# repo that already existed before init.templateDir was set — git only
# populates hooks from the template at init/clone time, so pre-existing
# repos need this once. New repos get it automatically from then on.
#
# Safe to rerun: `git init` never overwrites an existing hook file (verified
# 2026-09-20) — a repo with its own commit-msg hook is left alone and
# reported instead of clobbered.
set -euo pipefail

root="${1:-$HOME/projects}"
found=0 added=0 skipped=0

while IFS= read -r -d '' gitdir; do
    repo="$(dirname "$gitdir")"
    found=$(( found + 1 ))
    if [ -f "$gitdir/hooks/commit-msg" ] && ! grep -q check-ai-footer.sh "$gitdir/hooks/commit-msg" 2>/dev/null; then
        echo "backfill: $repo has its own commit-msg hook — leaving it, add the AI-footer check to it by hand"
        skipped=$(( skipped + 1 ))
        continue
    fi
    git -C "$repo" init -q
    added=$(( added + 1 ))
done < <(find "$root" -type d -name .git -print0)

echo "backfill: $found repos under $root, $added hooked, $skipped skipped (custom hook)"
