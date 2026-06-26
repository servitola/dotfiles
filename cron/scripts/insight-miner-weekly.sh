#!/bin/zsh
# insight-miner: weekly Telegram nudge (0 LLM). Sends compact digest to 🧠 Insights topic.
# Activation needs INSIGHT_TG_THREAD (topic id). Falls back to skipping if unset.
set -e
DIR="$HOME/projects/dotfiles"
CHAT="${INSIGHT_TG_CHAT:--1003172923198}"
THREAD="${INSIGHT_TG_THREAD:-}"
TEXT="$(python3 "$DIR/claude-code/skills/insight-miner/scripts/collect.py" tg --days 7)"
[ -z "$THREAD" ] && { echo "[skip] INSIGHT_TG_THREAD unset; digest:"; echo "$TEXT"; exit 0; }
"$DIR/cron/scripts/tg-send-thread.sh" "$CHAT" "$THREAD" "$TEXT"
