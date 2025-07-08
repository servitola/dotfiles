#!/bin/bash

set -e

echo "Downloading and Installing Ableton Remote Script..."
curl -L -o /tmp/ableton_remote.py https://raw.githubusercontent.com/ahujasid/ableton-mcp/main/AbletonMCP_Remote_Script/__init__.py

for app in "/Applications"/Ableton*; do
    if [[ -d "$app" ]]; then
        REMOTE_DIR="$app/Contents/App-Resources/MIDI Remote Scripts/AbletonMCP"
        mkdir -p "$REMOTE_DIR"
        cp /tmp/ableton_remote.py "$REMOTE_DIR/__init__.py"
        echo "✅ Installed to: $app"
        break
    fi
done

rm /tmp/ableton_remote.py

echo ""
echo "🎹 Setup Complete!"
echo "1. Start Ableton → Preferences → Link, Tempo & MIDI → Control Surface: 'AbletonMCP'"
echo "2. Restart Claude Desktop"
echo "3. Ask Claude: 'Create a deep house track with atmospheric intro'"
