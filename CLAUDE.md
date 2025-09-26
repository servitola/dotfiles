## Overview

dotfiles repository with @./README.md
Makefile is for symlinks generation and macos setup
Use homebrew and
Use @homebrew/brewfile to see what apps installed

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
