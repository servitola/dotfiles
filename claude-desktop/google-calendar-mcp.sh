#!/bin/bash

# Google Calendar MCP Server Wrapper
# Sources environment and launches with OAuth credentials

source ~/.config/openai_key.sh

# Set the OAuth credentials path with absolute path (no tilde)
export GOOGLE_OAUTH_CREDENTIALS="/Users/servitola/.config/claude-mcp/google-calendar-credentials.json"

exec npx @cocal/google-calendar-mcp
