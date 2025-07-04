#!/bin/bash

source ~/.config/openai_key.sh

export GOOGLE_OAUTH_CREDENTIALS="~/.config/claude-mcp/google-calendar-credentials.json"

exec npx @cocal/google-calendar-mcp
