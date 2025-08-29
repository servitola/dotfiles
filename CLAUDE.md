# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a comprehensive macOS dotfiles repository that configures a complete development environment for a mobile fintech CTO working with .NET 8, React, and cross-platform mobile development.

## Installation & Setup

- **Primary installation command**: `make` (from the repository root)
- **Repository location**: Must be cloned to `~/projects/dotfiles`
- **Shell**: zsh with oh-my-zsh and powerlevel10k theme

## Key Commands

- **Update all applications**: `up` or `u` - Updates all homebrew packages, npm packages, and cleans caches
- **Reload shell**: `reload` or `re` - Reexecs zsh with new configurations
- **Claude Code**: `a` - Alias for `claude -c`
- **File listing**: `ls` or `e` - Uses eza with custom theming
- **System monitoring**: `btop`, `t`, or `b` - System resource monitoring
- **File manager**: `yazi` - Terminal file manager
- **Search**: `d` - DuckDuckGo search via ddgr

### YouTube Download
- **Video**: `ytv` or `ytvideo` - Downloads video using custom config
- **Audio**: `yta` or `ytaudio` - Downloads audio as mp3 using custom config

## Architecture Overview

### Core System Components
- **Hammerspoon**: Primary automation and hotkey management (lua-based)
- **Karabiner-Elements**: Low-level keyboard remapping
- **Goku**: Configuration management for Karabiner using EDN format

### Window Management
- **Hotkeys**: `ctrl + alt + arrow keys` for 4-position window management
- **Hammerspoon Spoons**: Modular system for window control, audio switching, URL dispatching

### Development Environment
- **Terminal**: iTerm2 with custom profiles and hotkeys
- **Editor Integration**: VSCode, Windsurf, and JetBrains Rider configurations
- **Git**: Custom aliases and configurations in `git/aliases.gitconfig`

### Key Configuration Files
- **Hammerspoon config**: `hammerspoon/init.lua` - Main automation entry point
- **Hotkeys**: `hammerspoon/Spoons/HotKeys.spoon/init.lua` - Comprehensive keyboard shortcuts
- **URL Dispatcher**: `hammerspoon/config_UrlDispatcher.lua` - Routes work/personal links to different browsers
- **ZSH config**: Split across multiple files in `zsh/` directory for modularity

### Application-Specific Configurations
- **Context Menu**: Extensive right-click menu extensions in Finder
- **Claude Desktop**: MCP server configurations for various integrations
- **yt-dlp**: Separate audio and video download configurations
- **Browser Extensions**: Pre-configured Vimium and ImprovedTube settings

## Development Workflow

### Homebrew Management
- **All packages**: `homebrew/brewfile` - Complete application list
- **Minimum setup**: `homebrew/minimum_brewfile` - Essential tools only
- **Installation scripts**: Separate scripts for full and minimal installs

### File Organization
- **Symlink-based**: All configurations use symlinks to maintain central management
- **Modular structure**: Each application has its own directory with related configs
- **Version controlled**: All settings tracked in git with meaningful commit messages

### Automation Features
- **Language switching**: Automatic keyboard layout changes based on focused application
- **Audio management**: Smart audio device switching via Hammerspoon
- **URL routing**: Work URLs open in Safari, personal in other browsers
- **Screenshot tools**: Shottr integration for annotated screenshots

## Important Notes

- **Windsurf rules**: Additional AI coding rules in `windsurf/global_rules.md`
- **Security**: Uses LuLu firewall and has configurations for secure browsing
- **Mobile development**: Supports React Native, Appium testing, and cross-platform tooling
- **Git workflow**: Custom rebase scripts and aliases for development branch management

## System Integration

The configuration creates a cohesive environment where:
- Keyboard shortcuts are consistent across all applications
- File management is enhanced with custom context menus
- Development tools are integrated with unified settings
- System maintenance is automated via the `up` command
- Window management provides precise 4-quadrant positioning