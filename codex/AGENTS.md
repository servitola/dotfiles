# codex — OpenAI Codex CLI global config, owned by the dotfiles repo.

> **Status:** experiment — Claude Code is the primary AI coding agent. See `docs/repo-map.md`.

- **Skills**: Codex loads shared skills via `~/.agents/skills` → `claude-code/skills` (Makefile-managed; whole-dir symlink, verified working on 0.139). New skills in `claude-code/skills/` appear in Codex automatically after restart. `~/.codex/skills` is the deprecated location — it holds only Codex's own system-skills cache (`.system/`), written by Codex itself; never touch it. Codex silently skips skills with frontmatter `description` > 1024 chars or `name` > 64 — the `lint-skill-frontmatter` pre-commit hook enforces these limits. Reverse share: `claude-code/skills/openai-docs` is a vendored copy of Codex's built-in `~/.codex/skills/.system/openai-docs` (re-copy manually after notable Codex updates; in Codex the user-scope copy shadows the system one — no duplicate).
