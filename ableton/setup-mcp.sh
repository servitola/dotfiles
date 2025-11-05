#!/bin/zsh
set -e

echo "🎹 Installing Ableton MCP Server..."
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

echo "🎹 Ableton MCP setup complete"
echo "WARN!!! Start Ableton → Preferences → Link, Tempo & MIDI → Control Surface: 'AbletonMCP'"
