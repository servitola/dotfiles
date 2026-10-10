# claude-code — the Claude Code harness (hooks, settings, agents, scripts); skills and commands live in $DIR_SKILLS

`~/.claude` is a symlink to this directory. `skills/`, `detached_skills/` and `commands/` inside it are symlinks into `$DIR_SKILLS` (`~/projects/skills`, private; moved out on 2026-10-10), created by `install/08-ai-tools-links.sh` and git-ignored — so Claude Code, Codex (`~/.agents/skills`), OpenCode and the friends' bots keep their usual paths. To run this harness with your own skills: set `DIR_SKILLS` in `constants.env`, put `skills/`, `detached_skills/`, `commands/` there, run `zsh install/08-ai-tools-links.sh`. `agents/` stays here: it is harness, not content.

## Symlink targets (created by Makefile)
- `~/.codex/config.toml` → `codex/config.toml`
- `~/.codex/AGENTS.md` → repo-root `AGENTS.md`
- `~/.codex/instructions.md` → `claude-code/CLAUDE.md`
- `~/.agents/skills` → `claude-code/skills` (Codex skills — current location; `~/.codex/skills` is deprecated)

## Tool-specific configs (not shared)
- `codex/config.toml` — Codex's own global config

## Detached skills & MCP (opt-in, zero always-loaded context cost)
- `detached_skills/` — skills excluded from the always-loaded global set so their descriptions don't cost context in every session. Attach per folder: `skill-attach <name> [dir]` (symlinks into `<dir>/.claude/skills/`), list with `skill-attach`, remove with `skill-attach --detach <name> [dir]`.
- `detached_mcp/` — MCP server snippets removed from global `~/.claude.json`. Attach per folder: `mcp-attach <name> [dir]` (merges into `<dir>/.mcp.json`).

## Codex operational notes
- Codex picks up shared skills via `~/.agents/skills` (symlinked dir works; new skills appear automatically, restart Codex to rescan).
- Do not touch `~/.codex/skills`: it holds only Codex's built-in system skills cache (`.system/`), written by Codex itself.
- Codex silently skips skills whose frontmatter `description` exceeds 1024 chars (or `name` > 64) — enforced by the `lint-skill-frontmatter` pre-commit hook.
- `skills/openai-docs` is vendored from Codex's built-in system skills (`~/.codex/skills/.system/openai-docs`); re-copy it manually if a Codex update improves it.
- Codex is installed via Homebrew cask only (`cask "codex"`); never add the npm `@openai/codex` duplicate back. Never `brew uninstall --zap codex` — its zap stanza deletes `~/.codex`.
