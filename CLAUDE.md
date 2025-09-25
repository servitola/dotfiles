# CLAUDE.md

## Overview

dotfiles repository with README.md
There Makefile for symlinks generation
Use homebrew/brewfile

## Quick Commands
- `make install` - Full dotfiles installation & symlink setup
- `make n8n` - Setup n8n workflow automation
- `up` or `u` - System-wide update & cleanup (brew, npm, macOS, cache)
- `a` - claude -c (Claude Code shortcut)

## Architecture

### Directory Structure
├── bat
│   ├── config
│   └── themes
├── btop
│   ├── btop.conf
│   └── themes
├── chromium-ImprovedTube-extension
│   └── improvedtube.json
├── chromium-vimium-extension
│   └── vimium-options.json
├── claude-code
│   └── settings.json
├── claude-desktop
│   ├── claude_desktop_config.json
│   ├── deepseek-mcp.sh
│   ├── github-mcp.sh
│   ├── google-calendar-mcp.sh
│   └── google-maps-mcp.sh
├── CLAUDE.md
├── eza
│   ├── colors.sh
│   └── theme.yml
├── fork
│   └── custom-commands.json
├── git
│   ├── aliases.gitconfig
│   ├── colors.gitconfig
│   └── gitconfig
├── hammerspoon
│   ├── config_UrlDispatcher.lua
│   ├── init.lua
│   ├── lib
│   ├── reload_hammerspoon_on_script_changed.lua
│   ├── set_language_on_app_focused.lua
│   └── Spoons
├── homebrew
│   ├── brewfile
│   ├── examples
│   ├── install_all_homebrew_packages.sh
│   ├── install_minimum_homebrew_packages.sh
│   ├── install.sh
│   ├── minimum_brewfile
│   └── Support
├── iina
│   └── servitola.conf
├── images
│   ├── avatars
│   ├── icons
│   └── wallpapers
├── iterm
│   ├── com.googlecode.iterm2.plist
│   └── servitola_profile.json
├── jetbrains android
│   └── settings.zip
├── jetbrains rider
│   ├── rider.vmoptions
│   └── settings.zip
├── jetbrains webstorm
│   └── settings.zip
├── karabiner
│   ├── assets
│   ├── automatic_backups
│   └── karabiner.json
├── keyboard-layout
│   ├── English - IBT Custom.icns
│   └── English - IBT Custom.keylayout
├── lulu
│   ├── preferences.plist
│   └── rules.plist
├── macos
│   ├── ~
│   ├── dock_setup.sh
│   ├── hosts
│   ├── set_default_apps.sh
│   ├── set_defaults.sh
│   ├── sync_gruvbox_wallpapers.sh
│   └── update_all_and_cleanup_all.sh
├── Makefile
├── midnight commander
│   ├── ini
│   └── panels.ini
├── n8n
│   ├── com.colima.docker.plist
│   ├── com.n8n.workflow.plist
│   ├── docker-compose.yml
│   ├── env.example
│   └── setup.sh
├── npm
│   ├── global-packages.txt
│   ├── install-globals.sh
│   └── package.json
├── nvim
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lazyvim.json
│   ├── LICENSE
│   ├── lua
│   ├── README.md
│   └── stylua.toml
├── README.md
├── stylus
│   └── stylus-2021-11-19.json
├── Support
│   └── lporg
├── vscode
│   ├── keybindings.json
│   └── settings.json
├── xcode
│   ├── install.sh
│   └── KeyBindings
├── yazi
│   └── main.lua
├── yt-dlp
│   ├── audioConfig
│   ├── audioConfig_opus
│   ├── config
│   └── videoConfig
└── zsh
    ├── aliases.sh
    ├── completion.sh
    ├── exports.sh
    ├── functions.sh
    ├── fzf-tab-config.sh
    ├── fzf.sh
    ├── history_settings.sh
    ├── p10k.zsh
    ├── plugins
    ├── plugins.sh
    ├── secrets
    ├── setup_zsh.sh
    ├── zoxide.sh
    ├── zprofile.sh
    └── zshrc.sh


### Symlink Strategy
Instead of copying files, the repository creates symlinks from system locations to the dotfiles repository:
- Git config: `~/.gitconfig` → `~/projects/dotfiles/git/gitconfig`
- Application configs link to their respective directories in the repo

### Key Integrations
- **Hammerspoon**: Central automation hub for window management, URL routing, keyboard layouts, and custom Spoons
- **Karabiner-Elements**: Advanced keyboard customization
- **Zsh + Oh My Zsh**: Shell with extensive plugin ecosystem
- **n8n**: Workflow automation with Docker, auto-starting via LaunchAgents

## Important Notes

- The repository assumes installation at `~/projects/dotfiles/` - paths are hardcoded
- The `up` command performs comprehensive system maintenance including cache cleaning
