#!/bin/zsh
# Sends file(s) to a personal Telegram bot (acts as Saved Messages).
# Uses TELEGRAM_SERVITOLA_HOME_MAC_BOT + TELEGRAM_MY_MAIN_PROFILE_USER_ID from ~/.config/openai_key.sh.

notify() {
    osascript -e "display notification \"$1\" with title \"Send to Telegram\"" >/dev/null 2>&1
}

if [ ! -f "$HOME/.config/openai_key.sh" ]; then
    notify "missing ~/.config/openai_key.sh"
    exit 1
fi
source "$HOME/.config/openai_key.sh"

token="$TELEGRAM_BOT_HTTP_API_TOKEN"
chat_id="$TELEGRAM_MY_MAIN_PROFILE_USER_ID"

if [ -z "$token" ] || [ -z "$chat_id" ]; then
    notify "TELEGRAM_BOT_HTTP_API_TOKEN or TELEGRAM_MY_MAIN_PROFILE_USER_ID not set"
    exit 1
fi

ok=0
fail=0
for file in "$@"; do
    [ -f "$file" ] || { fail=$((fail+1)); continue; }
    mime=$(file --mime-type -b "$file")
    case "$mime" in
        image/*)
            method="sendPhoto"; field="photo" ;;
        video/*)
            method="sendVideo"; field="video" ;;
        audio/*)
            method="sendAudio"; field="audio" ;;
        *)
            method="sendDocument"; field="document" ;;
    esac
    http_code=$(curl -s -o /tmp/tg_send.out -w "%{http_code}" \
        -F "chat_id=${chat_id}" \
        -F "${field}=@${file}" \
        "https://api.telegram.org/bot${token}/${method}")
    if [ "$http_code" = "200" ]; then
        ok=$((ok+1))
    else
        fail=$((fail+1))
    fi
done

if [ "$fail" -eq 0 ]; then
    notify "sent ${ok} file(s)"
else
    notify "sent ${ok}, failed ${fail}"
fi
