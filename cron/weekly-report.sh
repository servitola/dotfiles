#!/bin/zsh
# Weekly cron health report -> the Telegram topic $TG_THREAD_CRON in $TG_CHAT_NOTIFY.
# Regenerates the HTML calendar first (the link target of the message), then
# pushes one compact message built by cron-report.py.
set -euo pipefail

HERE=${0:a:h}
CHAT=${TG_CHAT_NOTIFY:?}
THREAD=${TG_THREAD_CRON:?}

python3 "$HERE/cron-calendar.py" >/dev/null 2>&1 || true
TEXT="$(python3 "$HERE/cron-report.py")"

tg -c "$CHAT" -t "$THREAD" --parse-mode HTML -- "$TEXT"
