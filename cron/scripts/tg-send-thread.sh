#!/bin/zsh
# Send a Telegram message into a forum topic thread via local bot API server.
# Usage: tg-send-thread.sh <chat_id> <message_thread_id> <text>
set -e

source /Users/servitola/projects/services/telegram-bot/scripts/.env

CHAT_ID="$1"
THREAD_ID="$2"
TEXT="$3"

# Escape backslashes and double quotes for safe embedding in JSON.
ESCAPED_TEXT=${TEXT//\\/\\\\}
ESCAPED_TEXT=${ESCAPED_TEXT//\"/\\\"}

curl -s -X POST "http://localhost:8081/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\":${CHAT_ID},\"message_thread_id\":${THREAD_ID},\"text\":\"${ESCAPED_TEXT}\"}"
