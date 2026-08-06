#!/usr/bin/env bash

git diff --quiet && git diff --cached --quiet || { echo "Uncommitted changes — stash or commit first, then retry."; exit 1; }
echo "Undo: $(git rev-parse --short HEAD) -> $(git rev-parse --short ORIG_HEAD)  ($(git log -1 --format=%s ORIG_HEAD))"
git reset --hard ORIG_HEAD
