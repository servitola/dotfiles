#!/bin/zsh
# Send a Telegram message via local bot API server.
# Usage: tg-send.sh <chat_id> <text>
set -e

source /Users/servitola/projects/services/telegram-bot/scripts/.env

CHAT_ID="$1"
TEXT="$2"

curl -s -X POST "http://localhost:8081/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\":${CHAT_ID},\"text\":\"${TEXT}\"}"
