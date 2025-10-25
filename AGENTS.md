# Agent Guidelines for Dotfiles Repository

## Build/Lint/Test Commands
- `make` - Full dotfiles installation & symlink setup
- `up` - System-wide update & cleanup (brew, npm, macOS, cache)

## Architecture & Structure
- **Dotfiles repo**: Configuration files symlinked to system locations (~/.zshrc, ~/.gitconfig, etc.)
- **Package management**: Homebrew with brewfile for app installations
- **Automation**: Hammerspoon for window management, URL routing, keyboard layouts
- **Keyboard**: Karabiner-Elements for advanced keyboard customization
- **Shell**: Zsh + Oh My Zsh with extensive plugin ecosystem
- **Workflow**: n8n with Docker, auto-starting via LaunchAgents
- **No databases or APIs**: Pure configuration repository
- **Symlinks**: Created via Makefile (e.g., ~/.gitconfig → git/gitconfig; app configs link to respective directories)
- **Reference**: See @./README.md for detailed setup

## Code Style Guidelines
- **Theme**: Gruvbox Dark Hard
- **Naming**: Standard conventions per language/framework
- **Error handling**: Appropriate for shell scripts and config files
- **Linting**: No linting required - this is a configuration repository (shell scripts, Lua scripts, dotfiles)

## Adding New Applications/Tools

**Checklist:**
1. Create `~/projects/dotfiles/{app-name}/` directory (lowercase, hyphen-separated)
2. Add/copy config files to the directory
3. Add Makefile symlink commands using patterns below
4. Run `make` to test

**Makefile Integration:**
Add to `install` target:
```makefile
@echo "setup {app description}"
@mkdir -p {target_parent}
@$(REMOVE) {target_path}
@$(LINK) ~/projects/dotfiles/{app-dir}/{config_file} {target_path}
```

**Variables:** `REMOVE := sudo rm -rf`, `LINK := sudo ln -sfvh`, `COPY := sudo cp -r`

**Common Patterns:**
- **Single file**: `@$(LINK) ~/projects/dotfiles/app/config.json ~/.config/app/config.json`
- **Directory**: `@$(LINK) ~/projects/dotfiles/app ~/.config/app`
- **App Support**: `@$(LINK) ~/projects/dotfiles/app/config.plist ~/Library/Application\ Support/App/config.plist`

## Existing Rules Files
- CLAUDE.md: Points to this AGENTS.md file
