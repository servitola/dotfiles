#!/bin/zsh

echo "📦 Installing/updating global npm packages..."

while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines and comments
    [[ -z "$package" ]] && continue
    [[ "$package" =~ ^[[:space:]]*# ]] && continue

    # Check if already installed and if update available
    if npm list -g "$package" > /dev/null 2>&1; then

        current_version=$(npm list -g "$package" --depth=0 --json 2> /dev/null | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4)

        # Check if outdated and get latest version
        outdated_info=$(npm outdated -g "$package" --json 2> /dev/null)
        if [ -n "$outdated_info" ] && [ "$outdated_info" != "{}" ]; then
            latest_version=$(echo "$outdated_info" | grep -o '"latest": "[^"]*"' | cut -d'"' -f4)

            echo "🔄 Updating: $package ($current_version → $latest_version)"
            npm update -g "$package" 2>&1 | grep -v "^npm warn"
            if [ $? -eq 0 ]; then
                echo "✅ Updated: $package to $latest_version"
            else
                echo "❌ Failed to update: $package"
            fi
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
