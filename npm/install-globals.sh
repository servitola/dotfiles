#!/bin/zsh

echo
echo "📦 Installing/updating global npm packages..."

safe_npm_update() {
    local package="$1"
    local package_dir="$HOME/.npm-global/lib/node_modules/${package}"

    if [ -d "$package_dir" ]; then
        xattr -cr "$package_dir" 2>/dev/null || true
    fi

    npm install -g "$package@latest" 2>&1 | grep -v "^npm warn"
}

while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines and comments
    [[ -z "$package" ]] && continue
    [[ "$package" =~ ^[[:space:]]*# ]] && continue

    # Check if already installed and if update available
    if npm list -g "$package" > /dev/null 2>&1; then

        current_version=$(npm list -g "$package" --depth=0 --json 2> /dev/null | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4)

        # Check if outdated and get latest version
        # Get latest version from registry
        latest_version=$(npm view "$package" version 2> /dev/null)

        if [ -n "$latest_version" ] && [ "$current_version" != "$latest_version" ]; then
            echo "🔄 Updating: $package ($current_version → $latest_version)"
            safe_npm_update "$package"
            if [ $? -eq 0 ]; then
                echo "✅ Updated: $package to $latest_version"
            else
                echo "❌ Failed to update: $package"
            fi
        fi
    else
        echo "📥 Installing: $package"
        safe_npm_update "$package"
        if [ $? -eq 0 ]; then
            echo "✅ Installed: $package"
        else
            echo "❌ Failed to install: $package"
        fi
    fi
done < ~/projects/dotfiles/npm/global-packages.txt

echo "💾 Saving current global packages list..."
npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' | sort > ~/projects/dotfiles/npm/global-packages.txt

echo "✅ Global NPM packages ready"
