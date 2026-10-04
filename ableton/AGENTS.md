# Ableton MCP control-surface bridge

- Claude talks to Live through the `ableton-mcp-extended` MCP server (uv tool, installed from `~/projects/ableton_setup/ableton-mcp-extended`; config `claude-code/detached_mcp/ableton.mcp.json`).
- `setup-mcp.sh` (install step 13) copies the Remote Script from that same checkout into every installed Ableton Live, so server and script are always the same version. No Ableton installed: nothing happens.
- Until 2026-10-04 the step downloaded the original `ahujasid/ableton-mcp` script instead, which left Live running a different project's script than the server.
- Manual, once per Live install: Preferences → Link, Tempo & MIDI → Control Surface `AbletonMCP`.
