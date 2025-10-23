# Agent Guidelines for Dotfiles Repository

## Build/Lint/Test Commands
- `make` - Full dotfiles installation & symlink setup
- `up` - System-wide update & cleanup (brew, npm, macOS, cache)

## Architecture & Structure
- **Dotfiles repo**: Configuration files symlinked to system locations (~/.zshrc, ~/.gitconfig, etc.)
- **Package management**: Homebrew with brewfile for app installations
- **Automation**: Hammerspoon for window management, URL routing, keyboard layouts
- **Keyboard**: Karabiner-Elements for advanced keyboard customization
- **No databases or APIs**: Pure configuration repository

## Code Style Guidelines
- **Theme**: Gruvbox Dark Hard
- **Naming**: Standard conventions per language/framework
- **Error handling**: Appropriate for shell scripts and config files

## Existing Rules Files
- CLAUDE.md: Repository overview and quick commands
