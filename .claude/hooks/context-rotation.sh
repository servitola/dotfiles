#!/bin/bash

# Context rotation hook for dotfiles
# Helps maintain relevant context when working on different aspects of dotfiles

# Get the files being worked on from arguments or recent git changes
files_context=""
if [[ $# -gt 0 ]]; then
    files_context="$*"
else
    # Get recently modified files
    files_context=$(git diff --name-only HEAD~1 2>/dev/null || git ls-files --modified 2>/dev/null || echo "")
fi

echo "🔄 Rotating context for dotfiles work..."

# Determine context based on file paths
context_areas=()

if echo "$files_context" | grep -q "hammerspoon"; then
    context_areas+=("hammerspoon")
fi

if echo "$files_context" | grep -q "karabiner"; then
    context_areas+=("karabiner")
fi

if echo "$files_context" | grep -q "zsh"; then
    context_areas+=("zsh")
fi

if echo "$files_context" | grep -q "homebrew\|Brewfile"; then
    context_areas+=("homebrew")
fi

if echo "$files_context" | grep -q "Makefile\|scripts"; then
    context_areas+=("automation")
fi

# Provide context-specific reminders
for area in "${context_areas[@]}"; do
    case $area in
        "hammerspoon")
            echo "🖥️  Hammerspoon Context:"
            echo "   - Test with 'hs.reload()' after changes"
            echo "   - Check hotkey conflicts in HotKeys.spoon"
            echo "   - Validate Lua syntax before committing"
            echo "   - Consider URL dispatcher rule impacts"
            ;;
        "karabiner")
            echo "⌨️  Karabiner Context:"
            echo "   - Validate JSON with: jq . karabiner/karabiner.json"
            echo "   - Test key mappings incrementally"
            echo "   - Check for modifier conflicts"
            echo "   - Verify application bundle IDs"
            ;;
        "zsh")
            echo "🐚 Zsh Context:"
            echo "   - Test config with: zsh -n zsh/zshrc"
            echo "   - Check plugin compatibility"
            echo "   - Verify export variables"
            echo "   - Test aliases and functions"
            ;;
        "homebrew")
            echo "🍺 Homebrew Context:"
            echo "   - Validate Brewfile syntax"
            echo "   - Check for deprecated packages"
            echo "   - Test installation on clean system"
            echo "   - Update mas app IDs if needed"
            ;;
        "automation")
            echo "⚙️  Automation Context:"
            echo "   - Test Makefile targets"
            echo "   - Verify symlink creation"
            echo "   - Check script permissions"
            echo "   - Test on multiple macOS versions"
            ;;
    esac
    echo ""
done

# If no specific context, provide general guidance
if [[ ${#context_areas[@]} -eq 0 ]]; then
    echo "📋 General Dotfiles Context:"
    echo "   - Always backup before major changes"
    echo "   - Test symlink integrity after modifications"
    echo "   - Run pre-commit hooks before pushing"
    echo "   - Document new features in README.md"
fi

exit 0