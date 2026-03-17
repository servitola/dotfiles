#!/bin/zsh

source ~/.config/openai_key.sh

export BRAVE_API_KEY="$BRAVE_API_KEY"

exec node $HOME/ai-setup/deepseek-mcp-server/server.js
