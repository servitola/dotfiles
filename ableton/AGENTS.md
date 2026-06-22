# ableton — one-shot installer for the Ableton MCP control-surface bridge

- `setup-mcp.sh` downloads the upstream `ableton-mcp` Remote Script (`AbletonMCP_Remote_Script/__init__.py` from github.com/ahujasid/ableton-mcp) and installs it.
- Manual follow-up required (script prints it): in Ableton, Preferences → Link, Tempo & MIDI → set a Control Surface to `AbletonMCP`. Only then does the MCP server connect to Live.
