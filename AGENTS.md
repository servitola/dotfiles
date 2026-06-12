# Agent Guidelines for Dotfiles Repository

These dotfiles are an operating system on top of macOS. Not just a set of configs, but a living, evolving workspace management system.

**New here? Read `docs/repo-map.md`** — it tiers every directory by importance
(Core / Important / Secondary / Peripheral / Experiment), so you know what
matters and what's just an experiment. Each directory also has its own
`AGENTS.md` with operational detail.

## Build/Test Commands
- `make` - Full dotfiles installation & symlink setup
- `up` - System-wide update & cleanup (brew, npm, macOS, cache)

## Architecture & Structure
- **Dotfiles repo**: Configuration files symlinked to system locations (~/.zshrc, ~/.gitconfig, etc.)
- **Package management**: Homebrew with brewfile for app installations and documentation in `/opt/homebrew/docs/`
- **Automation**: Hammerspoon for window management, URL routing, keyboard layouts
- **Keyboard**: Karabiner-Elements for advanced keyboard customization
- **Shell**: Zsh + Oh My Zsh with extensive plugin ecosystem
- **No databases or APIs**: Pure configuration repository
- **Symlinks**: Created via Makefile (e.g., ~/.gitconfig → git/gitconfig; app configs link to respective directories)
- **Reference**: See `README.md` for detailed setup

## AI Coding Tools — Shared Configuration
Claude Code (`claude-code/`) is the single source of truth for commands, agents, and skills.
Other AI coding tools (Amp, Qwen Code) symlink to claude-code's directories so they all share the same setup.
Codex keeps its own global config in `codex/`, but should reuse `claude-code/` for shared AI assets whenever the format is compatible.

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
- `~/.codex/config.toml` → `codex/config.toml`
- `~/.codex/AGENTS.md` → `AGENTS.md`
- `~/.codex/instructions.md` → `claude-code/CLAUDE.md`
- `~/.agents/skills` → `claude-code/skills` (Codex skills — current location; `~/.codex/skills` is deprecated)

**Tool-specific configs (not shared):**
- `amp/settings.json`, `amp/tools/` — Amp's own settings
- `qwen-code/settings.json` — Qwen's own settings (context comes from `claude-code/CLAUDE.md` via `~/.qwen/QWEN.md` symlink)
- `codex/config.toml` — Codex's own global config

**Detached skills & MCP (opt-in, not loaded globally):**
- `claude-code/detached_skills/` (+ same dir in `dotfiles_private`) — skills excluded from the always-loaded global set so their descriptions don't cost context in every session. Attach per folder: `skill-attach <name> [dir]` (symlinks into `<dir>/.claude/skills/`), list with `skill-attach`, remove with `skill-attach --detach <name> [dir]`.
- `claude-code/detached_mcp/` — MCP server snippets removed from global `~/.claude.json`. Attach per folder: `mcp-attach <name> [dir]` (merges into `<dir>/.mcp.json`).

When adding new shared commands, agents, or skills — add them to `claude-code/` only.
Codex picks up shared skills via `~/.agents/skills` (symlinked dir works; new skills appear automatically, restart Codex to rescan).
Do not touch `~/.codex/skills`: it holds only Codex's built-in system skills cache (`.system/`), written by Codex itself.
Codex silently skips skills whose frontmatter `description` exceeds 1024 chars (or `name` > 64) — enforced by the `lint-skill-frontmatter` pre-commit hook.
`claude-code/skills/openai-docs` is vendored from Codex's built-in system skills (`~/.codex/skills/.system/openai-docs`); re-copy it manually if a Codex update improves it.
Codex is installed via Homebrew cask only (`cask "codex"`); never add the npm `@openai/codex` duplicate back. Never `brew uninstall --zap codex` — its zap stanza deletes `~/.codex`.

## Code Style Guidelines
- **Theme**: Gruvbox Dark Hard
- **Naming**: Standard conventions per language/framework
- **Error handling**: Appropriate for shell scripts and config files
- **Fail-fast philosophy**: Do NOT add existence checks for dependencies, tools, or paths. If something required is missing, the script should fail loudly. This is intentional — it surfaces setup issues immediately.
- **Linting**: No linting required - this is a configuration repository (shell scripts, Lua scripts, dotfiles)

## Adding New Applications/Tools

See `docs/app-integration.md` for detailed integration guide.

## Keyboard Setup

See `docs/keyboard-setup.md` for complete keyboard customization documentation.

## Documentation Structure
- **docs/** - Specialized guides that AI can read selectively when needed
- Reference by plain path in backticks (`` `docs/filename.md` ``) — NEVER via `@path` import syntax: `@` force-loads the file into every session's context, recursively following the imported file's own `@` refs
