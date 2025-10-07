## Overview

dotfiles repository with @./README.md
Makefile is for symlinks generation and macos setup
Use homebrew and
Use @homebrew/brewfile to see what apps installed

## Important: No Linting Required
This is a dotfiles configuration repository. Do NOT run lint or typecheck commands as they don't apply to configuration files, shell scripts, and Lua scripts in this project.

## Quick Commands
- `make` - Full dotfiles installation & symlink setup
- `up` - System-wide update & cleanup (brew, npm, macOS, cache)

## Symlink Strategy
Instead of copying files, the repository creates symlinks from system locations to the dotfiles repository:
- Git config: `~/.gitconfig` → `~/projects/dotfiles/git/gitconfig`
- Application configs link to their respective directories

## Key Integrations
- **Hammerspoon**: Central automation hub for window management, URL routing, keyboard layouts, and custom Spoons
- **Karabiner-Elements**: Advanced keyboard customization
- **Zsh + Oh My Zsh**: Shell with extensive plugin ecosystem
- **n8n**: Workflow automation with Docker, auto-starting via LaunchAgents
