#!/bin/bash
# Build, install, and launch NotifyDaemon as a launchd LaunchAgent.
# Re-run after editing NotifyDaemon.swift — the agent is reloaded automatically.
set -euo pipefail

DOTFILES="$HOME/projects/dotfiles"
SRC="$DOTFILES/notifier"
BIN_DEST="$HOME/Applications/NotifyDaemon"
PLIST_DEST="$HOME/Library/LaunchAgents/com.servitola.notifyd.plist"
LABEL="com.servitola.notifyd"
LOG_DIR="$HOME/Library/Logs"

mkdir -p "$(dirname "$BIN_DEST")" "$LOG_DIR" "$(dirname "$PLIST_DEST")"

# 1. Compile Swift binary with Tahoe SwiftUI Liquid Glass support.
echo "→ compiling NotifyDaemon"
swiftc -O \
    -framework AppKit -framework SwiftUI -framework Foundation \
    -o "$BIN_DEST" "$SRC/NotifyDaemon.swift"

# 2. launchd LaunchAgent — start at login, relaunch on crash, log stdout/stderr.
cat > "$PLIST_DEST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>             <string>$LABEL</string>
    <key>ProgramArguments</key>  <array><string>$BIN_DEST</string></array>
    <key>RunAtLoad</key>         <true/>
    <key>KeepAlive</key>         <true/>
    <key>ProcessType</key>       <string>Interactive</string>
    <key>StandardOutPath</key>   <string>$LOG_DIR/notifyd.log</string>
    <key>StandardErrorPath</key> <string>$LOG_DIR/notifyd.log</string>
</dict>
</plist>
EOF

# 3. Reload — unload existing instance, load new one.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/$LABEL"

# 4. Sanity check — wait briefly, then verify process + socket exist.
sleep 1
PID="$(launchctl print "gui/$(id -u)/$LABEL" 2>/dev/null | awk '/pid =/ {print $3}')"
if [[ -n "$PID" && "$PID" != "0" ]]; then
    echo "✓ NotifyDaemon running pid=$PID"
    echo "  socket: $HOME/.notifyd.sock $([ -S "$HOME/.notifyd.sock" ] && echo OK || echo MISSING)"
    echo "  log:    $LOG_DIR/notifyd.log"
else
    echo "✗ NotifyDaemon failed to start. Check log:"
    tail -20 "$LOG_DIR/notifyd.log" 2>/dev/null
    exit 1
fi
