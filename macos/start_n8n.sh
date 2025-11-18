#!/bin/bash

# Wait for Colima to be ready
echo "Waiting for Colima to start..."
max_wait=60
counter=0
while ! colima status &>/dev/null; do
    if [ $counter -gt $max_wait ]; then
        echo "Colima failed to start within ${max_wait}s"
        exit 1
    fi
    sleep 1
    ((counter++))
done

echo "Colima is running"

# Navigate to n8n directory
cd ~/projects/n8n-ai-starter || exit 1

# Start n8n with cpu profile (for Mac)
docker compose --profile cpu up -d

echo "n8n AI starter kit started successfully"
echo "Access n8n at: http://localhost:5678"
echo "Access Qdrant at: http://localhost:6333"
echo "Access Ollama at: http://localhost:11434"
