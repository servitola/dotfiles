#!/bin/bash

source ~/.config/openai_key.sh

export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_API_TOKEN"

exec npx -y @modelcontextprotocol/server-github
