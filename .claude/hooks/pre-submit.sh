#!/bin/bash

# Pre-submit hook for dotfiles validation
# This hook runs before submitting changes to ensure configuration integrity

set -e

echo "🔍 Running dotfiles validation checks..."

# Check if we're in the dotfiles directory
if [[ ! -f "Makefile" ]] || [[ ! -f "CLAUDE.md" ]]; then
    echo "❌ Not in dotfiles repository root"
    exit 1
fi

validation_failed=0

# 1. Validate JSON files (Karabiner configuration)
echo "📄 Validating JSON files..."
for json_file in $(find . -name "*.json" -not -path "./node_modules/*" -not -path "./.git/*"); do
    if ! jq . "$json_file" >/dev/null 2>&1; then
        echo "❌ Invalid JSON: $json_file"
        validation_failed=1
    else
        echo "✅ Valid JSON: $json_file"
    fi
done

# 2. Check Lua syntax (Hammerspoon)
echo "🌙 Validating Lua files..."
if command -v lua >/dev/null 2>&1; then
    for lua_file in $(find hammerspoon -name "*.lua" 2>/dev/null || true); do
        if ! lua -c "loadfile('$lua_file')" >/dev/null 2>&1; then
            echo "❌ Invalid Lua syntax: $lua_file"
            validation_failed=1
        else
            echo "✅ Valid Lua: $lua_file"
        fi
    done
else
    echo "⚠️  Lua not available - skipping Lua validation"
fi

# 3. Check for broken symlinks
echo "🔗 Checking for broken symlinks..."
while IFS= read -r -d '' symlink; do
    if [[ -L "$symlink" ]] && [[ ! -e "$symlink" ]]; then
        echo "❌ Broken symlink: $symlink"
        validation_failed=1
    fi
done < <(find "$HOME" -type l -print0 2>/dev/null | grep -z "dotfiles" || true)

# 4. Validate shell scripts
echo "🐚 Validating shell scripts..."
for script in $(find . -name "*.sh" -not -path "./.git/*"); do
    if ! bash -n "$script" 2>/dev/null; then
        echo "❌ Invalid shell script: $script"
        validation_failed=1
    else
        echo "✅ Valid shell script: $script"
    fi
done

# 5. Check Brewfile syntax
echo "🍺 Validating Brewfile..."
if [[ -f "homebrew/brewfile" ]]; then
    # Basic validation - check for common syntax issues
    if grep -q "^[[:space:]]*tap\|^[[:space:]]*brew\|^[[:space:]]*cask\|^[[:space:]]*mas" "homebrew/brewfile"; then
        echo "✅ Brewfile appears valid"
    else
        echo "❌ Brewfile may have syntax issues"
        validation_failed=1
    fi
fi

# Report results
if [[ $validation_failed -eq 1 ]]; then
    echo "❌ Validation failed - please fix errors before submitting"
    exit 1
else
    echo "✅ All validations passed"
    exit 0
fi