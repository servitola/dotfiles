#!/bin/bash
# Stop hook: .git-hooks/*.sh must be <=40 lines, <=88 chars/line
MAX_LINES=40
MAX_WIDTH=88
HOOKS_DIR="$CLAUDE_PROJECT_DIR/.git-hooks"

[[ -d "$HOOKS_DIR" ]] || exit 0

violations=""
for script in "$HOOKS_DIR"/*.sh; do
  [[ -f "$script" ]] || continue
  name=$(basename "$script")
  line_count=$(wc -l < "$script" | tr -d ' ')
  wide_count=$(awk "length>$MAX_WIDTH" "$script" | wc -l | tr -d ' ')
  if [[ "$line_count" -gt "$MAX_LINES" ]]; then
    violations="$violations\n  $name: $line_count lines (max $MAX_LINES)"
  fi
  if [[ "$wide_count" -gt 0 ]]; then
    violations="$violations\n  $name: $wide_count lines exceed $MAX_WIDTH chars"
  fi
done

if [[ -n "$violations" ]]; then
  reason="Fix .git-hooks scripts:$violations"
  reason="$reason\nKeep scripts short and narrow."
  echo "{\"decision\":\"block\",\"reason\":\"$reason\"}"
fi
