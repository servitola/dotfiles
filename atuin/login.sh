#!/bin/zsh

# Atuin login check and setup script

set -e

# Check if already logged in
if ! atuin account status &>/dev/null 2>&1; then
    echo "📝 Atuin not logged in. Starting login..."
    atuin login

    if [ $? -eq 0 ]; then
        echo "✓ Atuin login successful"
    else
        echo "⚠ Atuin login cancelled or failed"
        exit 1
    fi
else
    echo "✓ Atuin already logged in"
fi

echo "✓ Atuin setup complete"
