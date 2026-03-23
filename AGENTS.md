# Agent Guidelines for Dotfiles Repository

These dotfiles are an operating system on top of macOS. Not just a set of configs, but a living, evolving workspace management system.

## Build/Test Commands
- `make` - Full dotfiles installation & symlink setup
- `up` - System-wide update & cleanup (brew, npm, macOS, cache)

## Architecture & Structure
- **Dotfiles repo**: Configuration files symlinked to system locations (~/.zshrc, ~/.gitconfig, etc.)
- **Package management**: Homebrew with brewfile for app installations and documentation in `/opt/homebrew/docs/`
- **Automation**: Hammerspoon for window management, URL routing, keyboard layouts
- **Keyboard**: Karabiner-Elements for advanced keyboard customization
- **Shell**: Zsh + Oh My Zsh with extensive plugin ecosystem
- **Workflow**: n8n with Docker, auto-starting via LaunchAgents
- **No databases or APIs**: Pure configuration repository
- **Symlinks**: Created via Makefile (e.g., ~/.gitconfig → git/gitconfig; app configs link to respective directories)
- **Reference**: See @./README.md for detailed setup

## AI Coding Tools — Shared Configuration
Claude Code (`claude-code/`) is the single source of truth for commands, agents, and skills.
Other AI coding tools (Amp, Qwen Code) symlink to claude-code's directories so they all share the same setup.

**Source directories (in dotfiles repo):**
- `claude-code/commands/` — slash commands
- `claude-code/agents/` — agent definitions
- `claude-code/skills/` — skill definitions

**Symlink targets (created by Makefile):**
- `~/.config/amp/commands` → `claude-code/commands`
- `~/.config/amp/agents` → `claude-code/agents`
- `~/.config/amp/skills` → `claude-code/skills`
- `~/.qwen/commands` → `claude-code/commands`
- `~/.qwen/agents` → `claude-code/agents`
- `~/.qwen/skills` → `claude-code/skills`

**Tool-specific configs (not shared):**
- `amp/settings.json`, `amp/tools/` — Amp's own settings
- `qwen-code/settings.json`, `qwen-code/QWEN.md` — Qwen's own settings

When adding new commands, agents, or skills — add them to `claude-code/` only. All tools pick them up automatically via symlinks.

## Code Style Guidelines
- **Theme**: Gruvbox Dark Hard
- **Naming**: Standard conventions per language/framework
- **Error handling**: Appropriate for shell scripts and config files
- **Fail-fast philosophy**: Do NOT add existence checks for dependencies, tools, or paths. If something required is missing, the script should fail loudly. This is intentional — it surfaces setup issues immediately.
- **Linting**: No linting required - this is a configuration repository (shell scripts, Lua scripts, dotfiles)

## Adding New Applications/Tools

See @./docs/app-integration.md for detailed integration guide.

## Keyboard Setup

See @./docs/keyboard-setup.md for complete keyboard customization documentation.

## Documentation Structure
- **docs/** - Specialized guides that AI can read selectively when needed
- Reference via `@./docs/filename.md` syntax
