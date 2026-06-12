#!/bin/zsh

# Remove macOS quarantine flags from applications and CLI cask binaries
# Useful after `brew upgrade` to avoid repeated "App downloaded from internet" prompts.
# CLI casks (codex, ngrok, ...) never land in /Applications — their binaries live in
# Caskroom and a stuck Gatekeeper first-exec evaluation hangs them forever, so sweep both.
function brew_unquarantine() {
    local apps_dir="/Applications"
    local caskroom_dir="$(brew --prefix)/Caskroom"
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
                (( ++removed_count ))  # pre-increment: (( x++ )) from 0 yields status 1 → err_exit trap
            else
                echo "  ⚠ $app (skipped - protected by system)"
                (( ++skipped_count ))
            fi
        fi
    done

    if [ -d "$caskroom_dir" ]; then
        echo ""
        echo "🔍 Scanning for quarantine flags in $caskroom_dir (CLI casks)..."
        echo ""

        # caskroom/<cask>/<version>/<file>: plain executable files only ((.x) qualifier),
        # (N) so an empty match expands to nothing under err_exit
        for bin in "$caskroom_dir"/*/*/*(N.x); do
            if xattr -p com.apple.quarantine "$bin" &>/dev/null; then
                if xattr -d com.apple.quarantine "$bin" 2>/dev/null; then
                    echo "  ✓ $bin"
                    (( ++removed_count ))
                else
                    echo "  ⚠ $bin (skipped - protected by system)"
                    (( ++skipped_count ))
                fi
            fi
        done
    fi

    echo ""
    echo "📊 Summary:"
    echo "  • Quarantine removed: $removed_count"
    echo "  • Skipped (system protected): $skipped_count"
}
