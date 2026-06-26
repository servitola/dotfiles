#!/bin/zsh
# insight-miner: nightly incremental capture (0 LLM). Appends to events.jsonl.
set -e
LOCK="$HOME/.local/state/insight-miner/scan.lock.d"
mkdir -p "$(dirname "$LOCK")"
mkdir "$LOCK" 2>/dev/null || { echo "[skip] previous scan running"; exit 0; }
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
python3 "$HOME/projects/dotfiles/claude-code/skills/insight-miner/scripts/collect.py" scan
