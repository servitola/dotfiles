#!/bin/zsh
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
# A copy, not a link: Codex writes its own state into config.toml, which a link
# would carry into this repo.
python3 "$DOTFILES/codex/materialize-config.py" \
    "$DOTFILES/codex/config.toml" "$HOME/.codex/config.toml" "$HOME"
ok "codex config.toml written"

section "OpenCode"
link_all \
    "$DOTFILES/opencode/opencode.json" "$CONFIG/opencode/opencode.json" \
    "$DOTFILES/opencode/tui.json"      "$CONFIG/opencode/tui.json" \
    "$DOTFILES/opencode/agents"        "$CONFIG/opencode/agents" \
    "$CLAUDE_CODE/commands"            "$CONFIG/opencode/commands"
# OpenCode gets its own agents: it refuses to start on Claude Code's named
# colours ("color: yellow"). Skills it reads from ~/.claude/skills directly.

section "single-file AI tools (Hermes, Crush, Mistral Vibe, Aider)"
link_all \
    "$DOTFILES/hermes/config.yaml"     "$HOME/.hermes/config.yaml" \
    "$DOTFILES/crush/crush.json"       "$CONFIG/crush/crush.json" \
    "$DOTFILES/mistral-vibe/config.toml" "$HOME/.vibe/config.toml" \
    "$DOTFILES/aider/aider.conf.yml"   "$HOME/.aider.conf.yml"
