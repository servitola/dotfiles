#!/bin/zsh
# Step 08 — AI tools. $CLAUDE_CODE is the source of truth; others link into it.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "Claude"
link_all \
    "$CLAUDE_CODE"                     "$HOME/.claude" \
    "$DOTFILES/claude-code-memory"     "$CLAUDE_PROJECT/memory"

section "Codex"
link_all \
    "$DOTFILES/AGENTS.md"              "$HOME/.codex/AGENTS.md" \
    "$CLAUDE_CODE/CLAUDE.md"           "$HOME/.codex/instructions.md" \
    "$CLAUDE_CODE/skills"              "$HOME/.agents/skills"
# config.toml is materialized as a REAL file, NOT symlinked: Codex writes its
# project-trust registry (plus plugin/notice/tui state) straight into it, which
# — via a symlink — pushed machine-local runtime state into the dotfiles repo.
# The script keeps the authored head from the repo, preserves Codex's managed
# tail locally, and drops ephemeral trust (anything not under $HOME/projects).
python3 "$DOTFILES/codex/materialize-config.py" \
    "$DOTFILES/codex/config.toml" "$HOME/.codex/config.toml" "$HOME"
ok "codex config.toml materialized (real file — trust stays local, out of git)"

section "OpenCode"
link_all \
    "$DOTFILES/opencode/opencode.json" "$CONFIG/opencode/opencode.json" \
    "$DOTFILES/opencode/tui.json"      "$CONFIG/opencode/tui.json" \
    "$DOTFILES/opencode/agents"        "$CONFIG/opencode/agents" \
    "$CLAUDE_CODE/commands"            "$CONFIG/opencode/commands"
# opencode/agents/ is its OWN dotfiles dir, deliberately NOT $CLAUDE_CODE/agents:
# opencode 1.18 validates agent frontmatter strictly (color must be hex or its
# own enum) and hard-aborts startup on the Claude-Code files' named colors
# ("color: yellow"), which manifested as "CC TUI start timeout". Skills still
# flow from ~/.claude/skills (opencode scans it natively) — only agents need
# an opencode-specific, hex-colored copy.

section "single-file AI tools (Hermes, Crush, Mistral Vibe, Aider)"
link_all \
    "$DOTFILES/hermes/config.yaml"     "$HOME/.hermes/config.yaml" \
    "$DOTFILES/crush/crush.json"       "$CONFIG/crush/crush.json" \
    "$DOTFILES/mistral-vibe/config.toml" "$HOME/.vibe/config.toml" \
    "$DOTFILES/aider/aider.conf.yml"   "$HOME/.aider.conf.yml"
