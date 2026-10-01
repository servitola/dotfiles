#!/usr/bin/env bash
# A workspace wins over a bare project: CocoaPods and multi-project setups only build from the workspace.
# Nested ones (ios/, macos/ in Flutter or React Native repos) are found one level down.
source "$(dirname "$0")/lib.sh"
repo="$1"

find_one() {
  find "$repo" -maxdepth 2 -name "$1" \
    -not -path '*/.git/*' -not -path '*/Pods/*' -not -path '*/node_modules/*' \
    -not -path '*/DerivedData/*' -not -path '*/build/*' -not -path '*.xcodeproj/*' \
    | awk -F/ '{ print NF "\t" $0 }' | sort -n -k1,1 -k2 | head -1 | cut -f2
}

target=$(find_one '*.xcworkspace')
[ -n "$target" ] || target=$(find_one '*.xcodeproj')
[ -n "$target" ] || { [ -f "$repo/Package.swift" ] && target="$repo/Package.swift"; }

if [ -z "$target" ]; then
  alert "Open in Xcode" "No .xcworkspace, .xcodeproj or Package.swift in $repo"
  exit 1
fi
open -a Xcode "$target"
