#!/bin/zsh

source ~/.config/openai_key.sh

export GOOGLE_MAPS_API_KEY="$GOOGLE_API_KEY"

exec npx -y @modelcontextprotocol/server-google-maps
