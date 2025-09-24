#!/bin/bash

# Claude Code Configuration Setup Script
# This script sets up Claude Code with your dotfiles configuration

set -e

DOTFILES_DIR="$HOME/projects/dotfiles"
CLAUDE_CONFIG_DIR="$DOTFILES_DIR/claude-code-config"
CLAUDE_HOME="$HOME/.claude"

echo "🔧 Setting up Claude Code configuration..."

# Ensure Claude directory exists
if [ ! -d "$CLAUDE_HOME" ]; then
    echo "📁 Creating Claude home directory..."
    mkdir -p "$CLAUDE_HOME"
fi

# Backup existing configuration if it exists
if [ -f "$CLAUDE_HOME/settings.json" ]; then
    echo "💾 Backing up existing configuration..."
    cp "$CLAUDE_HOME/settings.json" "$CLAUDE_HOME/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy global configuration
echo "📋 Copying global settings..."
cp "$CLAUDE_CONFIG_DIR/settings.json" "$CLAUDE_HOME/settings.json"

# Set environment variables in shell profile
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
fi

if [ -n "$SHELL_PROFILE" ]; then
    echo "🐚 Adding environment variables to $SHELL_PROFILE..."
    
    # Check if Claude Code env vars are already set
    if ! grep -q "CLAUDE_CODE_ENABLE_TELEMETRY" "$SHELL_PROFILE"; then
        cat >> "$SHELL_PROFILE" << 'EOF'

# Claude Code Configuration
export CLAUDE_CODE_ENABLE_TELEMETRY=0
export DISABLE_ERROR_REPORTING=1
export DISABLE_TELEMETRY=1
export BASH_DEFAULT_TIMEOUT_MS=480000
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384
export ANTHROPIC_LOG=info

EOF
        echo "✅ Environment variables added to $SHELL_PROFILE"
    else
        echo "ℹ️  Environment variables already present in $SHELL_PROFILE"
    fi
fi

echo "✨ Claude Code configuration setup complete!"
echo ""
echo "📚 Available configurations:"
echo "  - Global settings: $CLAUDE_HOME/settings.json"
echo "  - Project template: $CLAUDE_CONFIG_DIR/project-settings.json"
echo "  - CLAUDE.md template: $CLAUDE_CONFIG_DIR/CLAUDE.md"
echo ""
echo "🚀 To apply to a project:"
echo "  1. Copy project-settings.json to your project's .claude/settings.json"
echo "  2. Copy CLAUDE.md to your project root"
echo "  3. Customize as needed"
echo ""
echo "🔄 Restart your terminal or run 'source $SHELL_PROFILE' to load environment variables"
