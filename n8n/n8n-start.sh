#!/bin/zsh

# n8n startup script — runs cleanup before launching n8n

N8N_DIR="/Users/servitola/projects/services/n8n/.n8n"
DB="$N8N_DIR/database.sqlite"
BINARY_DATA="$N8N_DIR/binaryData"
LOG="/Users/servitola/projects/services/n8n/n8n.log"

echo "[n8n-start] $(date) — starting cleanup" >> "$LOG"

# 1. Delete binary data files older than 3 days (macOS-compatible)
if [ -d "$BINARY_DATA" ]; then
    touch -t "$(date -v-3d '+%Y%m%d%H%M')" /tmp/n8n_cutoff
    find "$BINARY_DATA" -type f -not -name ".DS_Store" -not -newer /tmp/n8n_cutoff -delete
    rm -f /tmp/n8n_cutoff
    find "$BINARY_DATA" -type d -empty -delete 2>/dev/null || true
    echo "[n8n-start] binaryData cleanup done" >> "$LOG"
fi

# 2. VACUUM the SQLite DB to reclaim free pages
# Only run if free pages exceed 10% of total (avoids overhead on healthy DBs)
TOTAL=$(sqlite3 "$DB" "PRAGMA page_count;" 2>/dev/null || echo 0)
FREE=$(sqlite3 "$DB" "PRAGMA freelist_count;" 2>/dev/null || echo 0)

if [ "$TOTAL" -gt 0 ] && [ "$FREE" -gt 0 ]; then
    PCT=$(( FREE * 100 / TOTAL ))
    if [ "$PCT" -gt 10 ]; then
        echo "[n8n-start] VACUUM triggered (free pages: $FREE/$TOTAL = $PCT%)" >> "$LOG"
        sqlite3 "$DB" "VACUUM;" 2>> "$LOG"
        echo "[n8n-start] VACUUM done" >> "$LOG"
    fi
fi

echo "[n8n-start] launching n8n" >> "$LOG"

# 3. Start n8n
exec /Users/servitola/.npm-global/bin/n8n start
