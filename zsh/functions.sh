#!/bin/zsh

function mkd() {
    mkdir -p "$@" && cd "$_"
}

# Remove macOS quarantine flags from applications
# Useful after `brew upgrade` to avoid repeated "App downloaded from internet" prompts
function brew_unquarantine() {
    local apps_dir="/Applications"
    local removed_count=0
    local skipped_count=0

    if [ ! -d "$apps_dir" ]; then
        echo "❌ /Applications directory not found"
        return 1
    fi

    echo "🔍 Scanning for quarantine flags in $apps_dir..."
    echo ""

    for app in "$apps_dir"/*.app; do
        [ -d "$app" ] || continue

        # Check if quarantine flag exists
        if xattr -p com.apple.quarantine "$app" &>/dev/null; then
            # Try to remove quarantine
            if xattr -d com.apple.quarantine "$app" 2>/dev/null; then
                echo "  ✓ $app"
                ((removed_count++))
            else
                echo "  ⚠ $app (skipped - protected by system)"
                ((skipped_count++))
            fi
        fi
    done

    echo ""
    echo "📊 Summary:"
    echo "  • Quarantine removed: $removed_count"
    echo "  • Skipped (system protected): $skipped_count"
}
