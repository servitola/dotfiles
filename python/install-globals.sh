#!/bin/zsh

echo "🐍 Installing/updating global Python packages with uv..."

while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines and comments
    [[ -z "$package" ]] && continue
    [[ "$package" =~ ^[[:space:]]*# ]] && continue

    # Check if already installed
    if uv tool list 2>/dev/null | grep -q "^$package "; then
        current_version=$(uv tool list 2>/dev/null | grep "^$package " | awk '{print $2}' | tr -d 'v')
        
        echo "🔄 Upgrading: $package (v$current_version)"
        uv tool upgrade "$package" 2>&1 | grep -v "^warning"
        if [ $? -eq 0 ]; then
            new_version=$(uv tool list 2>/dev/null | grep "^$package " | awk '{print $2}' | tr -d 'v')
            if [ "$current_version" = "$new_version" ]; then
                echo "✅ Already up-to-date: $package v$new_version"
            else
                echo "✅ Upgraded: $package (v$current_version → v$new_version)"
            fi
        else
            echo "❌ Failed to upgrade: $package"
        fi
    else
        echo "📥 Installing: $package"
        uv tool install "$package" 2>&1 | grep -v "^warning"
        if [ $? -eq 0 ]; then
            version=$(uv tool list 2>/dev/null | grep "^$package " | awk '{print $2}' | tr -d 'v')
            echo "✅ Installed: $package v$version"
        else
            echo "❌ Failed to install: $package"
        fi
    fi
done < ~/projects/dotfiles/python/global-packages.txt

echo "✅ Global Python packages ready"
