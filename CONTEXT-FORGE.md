# Context Forge Integration for Dotfiles

Context Forge has been successfully integrated into your dotfiles repository to enhance AI-assisted development and configuration management.

## What Was Set Up

### 1. Configuration Files
- `.context-forge/config.json` - Main Context Forge configuration
- `context-forge.json` - Project-specific settings for dotfiles management

### 2. Product Requirement Prompts (PRPs)
Created specialized prompts for different aspects of dotfiles management:

- `PRPs/hammerspoon-config.md` - Guidelines for Hammerspoon Lua configuration
- `PRPs/karabiner-configuration.md` - Karabiner-Elements JSON configuration rules
- `PRPs/dotfiles-maintenance.md` - General dotfiles maintenance and validation

### 3. Claude Code Hooks
- `.claude/hooks/pre-submit.sh` - Validation hook that runs before submitting changes
  - Validates JSON files (Karabiner configuration)
  - Checks Lua syntax (Hammerspoon)
  - Identifies broken symlinks
  - Validates shell scripts
  - Checks Brewfile syntax

- `.claude/hooks/context-rotation.sh` - Context-aware guidance based on files being worked on

## How to Use Context Forge

### Important: Claude Code Interactive Mode Issue
**Note**: The `context-forge run-prp` command doesn't work with Claude Code because Claude requires an interactive terminal. Use these alternative approaches:

### Alternative 1: Use PRPs as Reference Context
```bash
# Start Claude Code manually
claude

# Then reference the PRP:
"Let's work on Hammerspoon config following the guidelines in PRPs/hammerspoon-config.md"
```

### Alternative 2: View and Apply PRPs Manually
```bash
# View PRP content
cat PRPs/hammerspoon-config.md

# Copy relevant sections to use with Claude Code
claude "Implement the Hammerspoon requirements from the PRP"
```

### Alternative 3: Use with Other AI Tools
```bash
# Context Forge works with Cursor and Windsurf (both in your brewfile)
# These tools may support non-interactive execution
context-forge run-prp hammerspoon-config
```

### Manual Validation
```bash
# Run pre-submit validation manually
.claude/hooks/pre-submit.sh

# Get context-specific guidance
.claude/hooks/context-rotation.sh hammerspoon/init.lua karabiner/karabiner.json
```

## Benefits for Your Dotfiles

### 1. Enhanced AI Context
- AI assistants now have specialized knowledge about your dotfiles structure
- Context-specific guidance for Hammerspoon, Karabiner, and other tools
- Better understanding of your symlink strategy and automation

### 2. Quality Assurance
- Pre-submit validation catches configuration errors before they break your system
- JSON syntax validation for Karabiner prevents keyboard mapping failures
- Lua syntax checking for Hammerspoon prevents automation breakage

### 3. Workflow Intelligence
- Context rotation provides relevant reminders based on what you're working on
- Specialized prompts guide you through complex configurations
- Integration with your existing `make` and `up` commands

### 4. Safety and Reliability
- Validation hooks prevent committing broken configurations
- Backup and testing reminders reduce risk of system disruption
- Structured approach to testing changes incrementally

## Current Validation Issues Found
The pre-submit hook identified several JSON files that need attention:
- `windsurf/User/settings.json` - Invalid JSON syntax
- `windsurf/User/keybindings.json` - Invalid JSON syntax
- Some Firefox configuration files

## Next Steps
1. Fix the identified JSON validation issues
2. Consider adding the pre-submit hook to your git pre-commit workflow
3. Use PRPs when working on complex configurations
4. Test the context rotation hook during your next dotfiles modifications

Context Forge is now ready to enhance your dotfiles development workflow with AI-powered guidance and validation!