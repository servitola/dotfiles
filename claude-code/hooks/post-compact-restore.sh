#!/bin/bash
# post-compact-restore.sh — Restore feature execution context after compaction.
# Triggered by SessionStart(compact) hook.
# Reads session_id from stdin, finds checkpoint, checks if this session is the team lead.

# Guard: jq required for JSON parsing
command -v jq &>/dev/null || exit 0

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0
[ -d "$CWD/work" ] || exit 0

# Find checkpoint in active features only (skip work/completed/).
# Takes the first active feature. Assumes one feature execution at a time.
CHECKPOINT=""
for dir in "$CWD"/work/*/logs/; do
  case "$dir" in
    "$CWD"/work/completed/*) continue ;;
  esac
  if [ -f "$dir/checkpoint.yml" ]; then
    CHECKPOINT="$dir/checkpoint.yml"
    break
  fi
done

[ -z "$CHECKPOINT" ] && exit 0

# Sanity check: checkpoint must be non-empty and under 64KB
CHECKPOINT_SIZE=$(wc -c < "$CHECKPOINT" 2>/dev/null || echo 0)
[ "$CHECKPOINT_SIZE" -eq 0 ] || [ "$CHECKPOINT_SIZE" -gt 65536 ] && exit 0

# Extract team name from checkpoint (strip quotes and whitespace)
TEAM_NAME=$(awk '/^team_name:/{sub(/^team_name:[[:space:]]*/,""); gsub(/["'"'"']/,""); print; exit}' "$CHECKPOINT")
[ -z "$TEAM_NAME" ] && exit 0

# Check if this session is the team lead.
# If team config exists — verify session_id matches lead.
# If team config is gone — still output recovery context (team needs to be recreated).
TEAM_CONFIG="$HOME/.claude/teams/$TEAM_NAME/config.json"
if [ -f "$TEAM_CONFIG" ]; then
  LEAD_SESSION=$(jq -r '.leadSessionId // empty' "$TEAM_CONFIG")
  [ "$LEAD_SESSION" != "$SESSION_ID" ] && exit 0
fi

# Output recovery context — this gets injected into agent's context after compaction
echo "Feature execution was in progress before context compaction."
echo "Load skill: feature-execution"
echo "Read checkpoint and decisions.md, then resume from the next pending wave."
echo ""
cat "$CHECKPOINT"
