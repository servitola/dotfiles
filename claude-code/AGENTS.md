# claude-code — shared AI-tool assets (commands, agents, skills) + Claude Code config

Single source of truth for `commands/`, `agents/`, `skills/` shared across Claude Code, Qwen Code, Codex. `~/.claude` is a symlink to this directory.

## Symlink targets (created by Makefile)
- `~/.qwen/commands` → `claude-code/commands`
- `~/.qwen/agents` → `claude-code/agents`
- `~/.qwen/skills` → `claude-code/skills`
- `~/.codex/config.toml` → `codex/config.toml`
- `~/.codex/AGENTS.md` → repo-root `AGENTS.md`
- `~/.codex/instructions.md` → `claude-code/CLAUDE.md`
- `~/.agents/skills` → `claude-code/skills` (Codex skills — current location; `~/.codex/skills` is deprecated)

## Tool-specific configs (not shared)
- `qwen-code/settings.json` — Qwen's own settings (context comes from `claude-code/CLAUDE.md` via `~/.qwen/QWEN.md` symlink)
- `codex/config.toml` — Codex's own global config

## Detached skills & MCP (opt-in, zero always-loaded context cost)
- `detached_skills/` (+ same dir in `dotfiles_private`) — skills excluded from the always-loaded global set so their descriptions don't cost context in every session. Attach per folder: `skill-attach <name> [dir]` (symlinks into `<dir>/.claude/skills/`), list with `skill-attach`, remove with `skill-attach --detach <name> [dir]`.
- `detached_mcp/` — MCP server snippets removed from global `~/.claude.json`. Attach per folder: `mcp-attach <name> [dir]` (merges into `<dir>/.mcp.json`).

## Codex operational notes
- Codex picks up shared skills via `~/.agents/skills` (symlinked dir works; new skills appear automatically, restart Codex to rescan).
- Do not touch `~/.codex/skills`: it holds only Codex's built-in system skills cache (`.system/`), written by Codex itself.
- Codex silently skips skills whose frontmatter `description` exceeds 1024 chars (or `name` > 64) — enforced by the `lint-skill-frontmatter` pre-commit hook.
- `skills/openai-docs` is vendored from Codex's built-in system skills (`~/.codex/skills/.system/openai-docs`); re-copy it manually if a Codex update improves it.
- Codex is installed via Homebrew cask only (`cask "codex"`); never add the npm `@openai/codex` duplicate back. Never `brew uninstall --zap codex` — its zap stanza deletes `~/.codex`.
