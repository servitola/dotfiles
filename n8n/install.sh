#!/bin/bash

set -e

# Script to call the main n8n-service.sh management script
SCRIPT_DIR="$HOME/projects/dotfiles/n8n"
N8N_SERVICE="$SCRIPT_DIR/n8n-service.sh"

# Make sure the service script is executable
chmod +x "$N8N_SERVICE"

# Create log directory if it doesn't exist
mkdir -p "$HOME/projects/services/n8n"

# Call the main service script with install command
exec "$N8N_SERVICE" install
