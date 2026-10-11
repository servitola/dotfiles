#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "skills repository (\$DIR_SKILLS)"
repository "$DIR_SKILLS"

section "Claude"
link_all \
    "$CLAUDE_CODE"                     "$HOME/.claude" \
    "$DOTFILES/claude-code-memory"     "$CLAUDE_PROJECT/memory"
[[ ! -d $DIR_SKILLS ]] || link_all \
    "$DIR_SKILLS/skills"               "$CLAUDE_CODE/skills" \
    "$DIR_SKILLS/detached_skills"      "$CLAUDE_CODE/detached_skills" \
    "$DIR_SKILLS/commands"             "$CLAUDE_CODE/commands" \
    "$DIR_SKILLS/agents"               "$CLAUDE_CODE/agents"

section "Codex"
link_all \
    "$DOTFILES/AGENTS.md"              "$HOME/.codex/AGENTS.md" \
    "$CLAUDE_CODE/CLAUDE.md"           "$HOME/.codex/instructions.md"
[[ ! -d $DIR_SKILLS ]] || link "$CLAUDE_CODE/skills" "$HOME/.agents/skills"
# A copy, not a link: Codex writes its own state into config.toml, which a link
# would carry into this repo.
python3 "$DOTFILES/codex/materialize-config.py" \
    "$DOTFILES/codex/config.toml" "$HOME/.codex/config.toml" "$HOME"
ok "codex config.toml written"

section "OpenCode"
link_all \
    "$DOTFILES/opencode/opencode.json" "$CONFIG/opencode/opencode.json" \
    "$DOTFILES/opencode/tui.json"      "$CONFIG/opencode/tui.json" \
    "$DOTFILES/opencode/agents"        "$CONFIG/opencode/agents"
[[ ! -d $DIR_SKILLS ]] || link "$CLAUDE_CODE/commands" "$CONFIG/opencode/commands"
# OpenCode gets its own agents: it refuses to start on Claude Code's named
# colours ("color: yellow"). Skills it reads from ~/.claude/skills directly.

section "Aider"
link_all \
    "$DOTFILES/aider/aider.conf.yml"   "$HOME/.aider.conf.yml"
