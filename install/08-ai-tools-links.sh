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
    "$DOTFILES/codex/config.toml"      "$HOME/.codex/config.toml" \
    "$DOTFILES/AGENTS.md"              "$HOME/.codex/AGENTS.md" \
    "$CLAUDE_CODE/CLAUDE.md"           "$HOME/.codex/instructions.md" \
    "$CLAUDE_CODE/skills"              "$HOME/.agents/skills"

section "Qwen Code"
link_all \
    "$DOTFILES/qwen-code/settings.json" "$HOME/.qwen/settings.json" \
    "$CLAUDE_CODE/CLAUDE.md"           "$HOME/.qwen/QWEN.md" \
    "$CLAUDE_CODE/skills"              "$HOME/.qwen/skills" \
    "$CLAUDE_CODE/agents"              "$HOME/.qwen/agents" \
    "$CLAUDE_CODE/commands"            "$HOME/.qwen/commands"

section "OpenCode"
link_all \
    "$DOTFILES/opencode/opencode.json" "$CONFIG/opencode/opencode.json" \
    "$CLAUDE_CODE/commands"            "$CONFIG/opencode/commands" \
    "$CLAUDE_CODE/agents"              "$CONFIG/opencode/agents"

section "single-file AI tools (Hermes, Crush, Mistral Vibe, Aider)"
link_all \
    "$DOTFILES/hermes/config.yaml"     "$HOME/.hermes/config.yaml" \
    "$DOTFILES/crush/crush.json"       "$CONFIG/crush/crush.json" \
    "$DOTFILES/mistral-vibe/config.toml" "$HOME/.vibe/config.toml" \
    "$DOTFILES/aider/aider.conf.yml"   "$HOME/.aider.conf.yml"
