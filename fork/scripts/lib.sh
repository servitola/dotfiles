#!/usr/bin/env bash
# Shared helpers for Fork custom-command scripts (sourced, not executed).
# alert TITLE MESSAGE   -> critical macOS alert (message truncated to 300 chars)
# notify MESSAGE        -> macOS notification titled "Fork"
# waitlock              -> block until the repo's index.lock clears (Fork holds it briefly)
alert()    { /usr/bin/osascript -e 'on run argv' -e 'display alert (item 1 of argv) message (item 2 of argv) as critical' -e 'end run' "$1" "$(printf '%s' "$2" | head -c 300)"; }
notify()   { /usr/bin/osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Fork"' -e 'end run' "$1"; }
waitlock() { i=0; while [ -f "$(git rev-parse --git-path index.lock 2>/dev/null)" ] && [ "$i" -lt 100 ]; do sleep 0.1; i=$((i+1)); done; }
