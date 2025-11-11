#!/bin/zsh

echo "🐍 Installing/updating global Python packages..."

while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^# ]] && continue
    uv pip install --upgrade "$package" 2>&1 | grep -v "^warning"
done < ~/projects/dotfiles/python/global-packages.txt

echo "💾 Saving global packages list..."
uv pip list 2>/dev/null | awk 'NR>3 {print $1}' | sort > ~/projects/dotfiles/python/global-packages.txt

echo "✅ Global packages ready"
