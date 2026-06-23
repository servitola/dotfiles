#!/bin/zsh
# reboot-reminder — native macOS notification nudging a reboot when uptime is high.
# A reboot resets the WindowServer/loginwindow creep that builds up over long
# uptimes (see ~/projects/serho_topics/перформанс-макбука/AGENTS.md).
#
# Run daily by the com.servitola.reboot-reminder LaunchAgent; self-gates on uptime
# so it only fires when there's actually something to gain (≥ THRESHOLD_DAYS).
emulate -L zsh

THRESHOLD_DAYS=7
TN=/opt/homebrew/bin/terminal-notifier

BOOT=$(sysctl -n kern.boottime 2>/dev/null | grep -oE 'sec = [0-9]+' | head -1 | grep -oE '[0-9]+')
[[ -n "$BOOT" ]] || exit 0
DAYS=$(( ($(date +%s) - BOOT) / 86400 ))
(( DAYS >= THRESHOLD_DAYS )) || exit 0
[[ -x "$TN" ]] || exit 0

"$TN" \
    -title "🔄 Пора перезагрузиться" \
    -subtitle "Аптайм ${DAYS} дн." \
    -message "Ребут сбросит разросшийся WindowServer/loginwindow и подчистит фон." \
    -sound default \
    -group com.servitola.reboot-reminder
