# qwen-code — Qwen Code terminal AI coding agent config in the dotfiles repo

> **Status:** experiment — Claude Code is the primary AI coding agent. See `docs/repo-map.md`.

- `settings.json` is Qwen's own config (not shared): model `coder-model`, `approvalMode: "plan"`, sandbox off, telemetry off, checkpointing on, theme GitHub. The `coder-model` name resolves through the local LiteLLM proxy (`litellm/`) — point that proxy at the actual backing model rather than hardcoding one here.
- Shared AI assets are NOT duplicated here: `~/.qwen/commands`, `~/.qwen/agents`, and `~/.qwen/skills` symlink to `claude-code/{commands,agents,skills}` (the single source of truth). Add or edit these in `claude-code/` only — never in `qwen-code/`.
- Qwen's context/instructions come from `claude-code/CLAUDE.md` via the `~/.qwen/QWEN.md` → `claude-code/CLAUDE.md` symlink. `settings.json` sets `context.fileName: "QWEN.md"` to load it.
- All the above symlinks are created by the repo `Makefile`. `qwen-code/` itself only holds `settings.json` (and `mcp/`, which `~/.qwen/mcp` links to).
- Invariant: keep this directory tool-specific. Anything meant to be shared across Claude Code  / Qwen belongs in `claude-code/`, not here.
