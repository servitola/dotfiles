#!/bin/bash

# Claude Code Project Initialization Script
# Quickly set up Claude Code configuration for a new project

set -e

PROJECT_NAME="$(basename $(pwd))"
DOTFILES_DIR="$HOME/projects/dotfiles"
CLAUDE_CONFIG_DIR="$DOTFILES_DIR/claude-code-config"

echo "🚀 Initializing Claude Code configuration for project: $PROJECT_NAME"

# Create .claude directory if it doesn't exist
if [ ! -d ".claude" ]; then
    echo "📁 Creating .claude directory..."
    mkdir -p .claude
fi

# Copy project settings template
echo "📋 Setting up project configuration..."
cp "$CLAUDE_CONFIG_DIR/project-settings.json" ".claude/settings.json"

# Copy CLAUDE.md template if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    echo "📝 Creating CLAUDE.md..."
    cp "$CLAUDE_CONFIG_DIR/CLAUDE.md" "./CLAUDE.md"
    
    # Customize CLAUDE.md with project name
    if command -v sed > /dev/null; then
        sed -i.bak "s/# Claude Code Project Configuration/# Claude Code Configuration for $PROJECT_NAME/" CLAUDE.md
        rm CLAUDE.md.bak 2>/dev/null || true
    fi
else
    echo "ℹ️  CLAUDE.md already exists, skipping..."
fi

# Add .claude/settings.local.json to .gitignore if .gitignore exists
if [ -f ".gitignore" ]; then
    if ! grep -q ".claude/settings.local.json" .gitignore; then
        echo "🙈 Adding .claude/settings.local.json to .gitignore..."
        echo ".claude/settings.local.json" >> .gitignore
    fi
fi

echo "✨ Project initialization complete!"
echo ""
echo "📁 Created files:"
echo "  - .claude/settings.json (project configuration)"
echo "  - CLAUDE.md (project memory and guidelines)"
echo ""
echo "🔧 Next steps:"
echo "  1. Review and customize .claude/settings.json for your project"
echo "  2. Update CLAUDE.md with project-specific information"
echo "  3. Run 'claude' to start Claude Code in this directory"
echo ""
echo "💡 Pro tip: Use '.claude/settings.local.json' for personal settings that shouldn't be committed"
