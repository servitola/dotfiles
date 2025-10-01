#!/bin/zsh

echo "📦 Installing/updating global npm packages...\n"

while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines and comments
    [[ -z "$package" ]] && continue
    [[ "$package" =~ ^[[:space:]]*# ]] && continue

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if already installed and if update available
    if npm list -g "$package" >/dev/null 2>&1; then
        # Check if outdated
        if npm outdated -g "$package" 2>/dev/null | grep -q "$package"; then
            echo "🔄 Updating: $package"
            npm update -g "$package" 2>&1 | grep -v "^npm warn"
            if [ $? -eq 0 ]; then
                echo "✅ Updated: $package"
            else
                echo "❌ Failed to update: $package"
            fi
        else
            echo "⏭️  Already up-to-date: $package"
        fi
    else
        echo "📥 Installing: $package"
        npm install -g "$package" 2>&1 | grep -v "^npm warn"
        if [ $? -eq 0 ]; then
            echo "✅ Installed: $package"
        else
            echo "❌ Failed to install: $package"
        fi
    fi
done < ~/projects/dotfiles/npm/global-packages.txt

echo "✅ Global NPM packages ready"
