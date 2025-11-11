#!/bin/zsh

echo "⚙️  Installing/updating UV tools..."
uv tool upgrade --all

echo "💾 Saving UV tools list..."
uv tool list 2>/dev/null | awk 'NR>1 {print $1}' | grep -v '^-$' | sort > ~/projects/dotfiles/python/uv-packages.txt

echo "✅ UV tools ready"
