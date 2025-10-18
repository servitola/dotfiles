#!/bin/bash

set -e

SCREENSAVER_URL="https://floor796.com/#wandering"
SCREENSAVER_NAME="WebViewScreenSaver"
SCREENSAVER_PATH="$HOME/Library/Screen Savers/${SCREENSAVER_NAME}.saver"
DOTFILES_DIR="$HOME/projects/dotfiles"

echo "🖥️  Setting up WebViewScreenSaver..."

defaults -currentHost write com.apple.screensaver moduleDict -dict \
    moduleName "$SCREENSAVER_NAME" \
    path "$SCREENSAVER_PATH" \
    type 0

defaults -currentHost write com.apple.screensaver idleTime 60

if [ -f "$DOTFILES_DIR/macos/webviewscreensaver_config.plist" ]; then
    echo "📋 Restoring saved configuration..."
    defaults -currentHost import WebViewScreenSaver "$DOTFILES_DIR/macos/webviewscreensaver_config.plist"
else
    echo "⚙️  Setting URL to: $SCREENSAVER_URL"
    defaults -currentHost write WebViewScreenSaver URLs -array "$SCREENSAVER_URL"
    defaults -currentHost write WebViewScreenSaver Times -array -1
fi

# Kill screensaver process to reload config
echo "🔄 Restarting screensaver engine..."
killall ScreenSaverEngine 2>/dev/null || true

echo ""
echo "🌐 Complete. Screensaver URL: $SCREENSAVER_URL"
