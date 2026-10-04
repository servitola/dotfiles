#!/bin/zsh
# The Remote Script comes from the same checkout as the MCP server Claude runs
# (uv tool ableton-mcp-extended), so the commands one sends are ones the other knows.
set -euo pipefail
setopt null_glob

script=$HOME/projects/ableton_setup/ableton-mcp-extended/AbletonMCP_Remote_Script/__init__.py
for app in /Applications/Ableton*.app; do
    target="$app/Contents/App-Resources/MIDI Remote Scripts/AbletonMCP"
    mkdir -p "$target"
    cp "$script" "$target/__init__.py"
    echo "AbletonMCP Remote Script -> $app (restart Live to load it)"
done
