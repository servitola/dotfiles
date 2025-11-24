# Agent Guidelines for Dotfiles Repository

## Build/Test Commands
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

See @./docs/app-integration.md for detailed integration guide.

## Keyboard Setup

See @./docs/keyboard-setup.md for complete keyboard customization documentation.

## Documentation Structure
- **docs/** - Specialized guides that AI can read selectively when needed
- Reference via `@./docs/filename.md` syntax


## Current Directory Structure (depth 2)
.
├── adguard
│   └── adg_settings.adg.adguardsettings
├── aichat
│   ├── rags
│   ├── roles
│   ├── config.yaml
│   └── dark.tmTheme
├── amp
│   ├── commands
│   ├── tools
│   └── settings.json
├── annepro2
│   ├── qmk
│   ├── layout.json
│   ├── lightning.json
│   ├── ObinsKit_1.2.11_x64.dmg
│   └── readme.md
├── atuin
│   ├── config.toml
│   └── login.sh
├── bat
│   └── config
├── btop
│   ├── themes
│   └── btop.conf
├── chromium-ImprovedTube-extension
│   └── improvedtube.json
├── chromium-vimium-extension
│   └── vimium-options.json
├── claude-code
│   ├── CLAUDE.md
│   └── settings.json
├── claude-desktop
│   ├── claude_desktop_config.json
│   ├── deepseek-mcp.sh
│   ├── github-mcp.sh
│   ├── google-calendar-mcp.sh
│   └── google-maps-mcp.sh
├── colima
│   └── default
├── contextMenu
│   ├── actions
│   └── helper_script.sh
├── cursor
│   ├── keybindings.json
│   └── settings.json
├── docs
│   ├── ai-development-best-practices.md
│   ├── app-integration.md
│   ├── claude-code-best-practices.md
│   ├── hammerspoon.md
│   ├── homebrew.md
│   ├── keyboard-setup.md
│   ├── letters.md
│   ├── README.md
│   └── shell-zsh.md
├── eza
│   ├── colors.sh
│   └── theme.yml
├── firefox vimimum addon
│   └── vimium-options.json
├── focusrite
│   ├── DAW 6x4.ff
│   ├── Default Direct Studio Setup.ff
│   └── Default Studio Setup.ff
├── fork
│   └── custom-commands.json
├── ghostty
│   └── config
├── git
│   ├── aliases.gitconfig
│   ├── colors.gitconfig
│   ├── gitconfig
│   └── global_ignore
├── hammerspoon
│   ├── Spoons
│   ├── config_UrlDispatcher.lua
│   ├── init.lua
│   ├── reload_hammerspoon_on_script_changed.lua
│   └── set_language_on_app_focused.lua
├── heroic
│   └── config.json
├── homebrew
│   ├── examples
│   ├── Support
│   ├── brewfile
│   ├── install_all_homebrew_packages.sh
│   ├── install_minimum_homebrew_packages.sh
│   ├── install.sh
│   └── minimum_brewfile
├── iina
│   └── servitola.conf
├── images
│   ├── avatars
│   ├── icons
│   └── wallpapers
├── iterm
│   ├── com.googlecode.iterm2.plist
│   ├── install.sh
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
│   ├── rules
│   └── karabiner.json
├── keyboard-layout
│   └── Birman.bundle
├── LaunchAgents
│   ├── com.colima.service.plist
│   └── com.telegram-bot.service.plist
├── lazydocker
│   └── config.yml
├── lazygit
│   └── config.yml
├── lulu
│   ├── preferences.plist
│   └── rules.plist
├── macos
│   ├── helpers
│   ├── dock_setup.sh
│   ├── hosts
│   ├── set_default_apps.sh
│   ├── set_defaults.sh
│   ├── sync_gruvbox_wallpapers.sh
│   └── update_all_and_cleanup_all.sh
├── marta
│   ├── plugins
│   ├── themes
│   ├── conf.marco
│   └── favorites.marco
├── midnight commander
│   ├── mcedit
│   ├── ini
│   └── panels.ini
├── n8n
│   ├── com.n8n.service.plist
│   ├── install.sh
│   ├── n8n-service.sh
│   └── README.md
├── nano
│   └── nanorc
├── noti
│   └── noti.yaml
├── npm
│   ├── global-packages.txt
│   └── install-globals.sh
├── nvim
│   ├── lua
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lazyvim.json
│   ├── LICENSE
│   ├── README.md
│   └── stylua.toml
├── python
│   ├── global-packages.txt
│   ├── install-globals.sh
│   ├── install-uv-tools.sh
│   └── uv-packages.txt
├── raycast
│   └── Raycast.rayconfig
├── vscode
│   ├── keybindings.json
│   └── settings.json
├── warp
│   ├── themes
│   └── keybindings.yaml
├── windsurf
│   ├── User
│   └── global_rules.md
├── xcode
│   ├── KeyBindings
│   └── install.sh
├── yazi
│   └── main.lua
├── yt-dlp
│   ├── audioConfig
│   ├── config
│   └── videoConfig
├── zsh
│   ├── bin
│   ├── plugins
│   ├── secrets
│   ├── aliases.sh
│   ├── completion.sh
│   ├── exports.sh
│   ├── functions.sh
│   ├── fzf-tab-config.sh
│   ├── fzf.sh
│   ├── history_settings.sh
│   ├── p10k.zsh
│   ├── plugins.sh
│   ├── setup_zsh.sh
│   ├── zprofile.sh
│   └── zshrc.sh
├── AGENTS.md
├── CLAUDE.md
├── Makefile
├── README.md
└── WARP.md -> CLAUDE.md
Finish of Directory Structure
