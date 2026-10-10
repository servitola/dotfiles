#!/bin/zsh
# Runs `tg` and the three legacy wrappers against a throwaway HTTP server that
# records every request, so nothing reaches Telegram.
set -euo pipefail
here=${0:a:h}
tg=$here/../bin/tg
scripts=${DIR_CRON_SCRIPTS:?}
work=$(mktemp -d)
trap 'kill $server 2>/dev/null; rm -rf "$work"' EXIT

python3 - "$work" <<'PY' &
import email, http.server, json, sys, urllib.parse
work = sys.argv[1]

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        ctype = self.headers.get("Content-Type", "")
        raw = self.rfile.read(int(self.headers["Content-Length"]))
        if ctype.startswith("multipart/"):
            msg = email.message_from_bytes(b"Content-Type: " + ctype.encode() + b"\r\n\r\n" + raw)
            fields = {}
            for part in msg.get_payload():
                name = part.get_param("name", header="content-disposition")
                fname = part.get_filename()
                fields[name] = f"<file {fname}>" if fname else part.get_payload(decode=True).decode()
        else:
            fields = dict(urllib.parse.parse_qsl(raw.decode(), keep_blank_values=True))
        open(f"{work}/last.json", "w").write(json.dumps({"path": self.path, "fields": fields}, ensure_ascii=False))
        fail = fields.get("text") == "boom"
        self.send_response(400 if fail else 200)
        self.end_headers()
        self.wfile.write(b'{"ok":false}' if fail else b'{"ok":true}')
    def log_message(self, *a): pass

srv = http.server.HTTPServer(("127.0.0.1", 0), Handler)
open(f"{work}/port", "w").write(str(srv.server_port))
srv.serve_forever()
PY
server=$!
for _ in {1..100}; do [[ -s $work/port ]] && break; sleep 0.05; done
[[ -s $work/port ]] || { print "FAIL: the stub server did not start"; exit 1 }

print "TELEGRAM_BOT_TOKEN=T0KEN\nTG_BOT_API=http://127.0.0.1:$(<$work/port)" > $work/env
# Without this guard every `#!/bin/zsh` child re-reads constants.env through
# ~/.zshenv and puts the real chats and the real bot back over the stub.
export _EXPORTS_LOADED=1
export FILE_TG_BOT_ENV=$work/env TG_CHAT_MAIN=-100111 TG_CHAT_NOTIFY=-100222
unset TG_CHAT_NOPE 2>/dev/null || true

n=0
last() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["path"], json.dumps(d["fields"], ensure_ascii=False, sort_keys=True))' $work/last.json }
check() {  # description, expected `last` output
  n=$((n+1))
  local got; got=$(last)
  [[ $got == $2 ]] || { print "FAIL $n: $1\n  want: $2\n  got:  $got"; exit 1 }
}
fails() {  # description, command…
  n=$((n+1))
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then print "FAIL $n: $d — expected a non-zero exit"; exit 1; fi
}

$tg "hello" >/dev/null
check "default chat is main" '/botT0KEN/sendMessage {"chat_id": "-100111", "text": "hello"}'

$tg -c notify -t 1486 "to a topic" >/dev/null
check "chat by name, thread" '/botT0KEN/sendMessage {"chat_id": "-100222", "message_thread_id": "1486", "text": "to a topic"}'

$tg -c -100333 "numeric chat" >/dev/null
check "numeric chat id" '/botT0KEN/sendMessage {"chat_id": "-100333", "text": "numeric chat"}'

tricky=$'quote " backslash \\ amp & plus + percent %\nsecond line @/etc/hosts'
$tg -- "$tricky" >/dev/null
[[ $(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["fields"]["text"])' $work/last.json) == $tricky ]] \
  || { print "FAIL: special characters did not survive"; exit 1 }
n=$((n+1))

print "from stdin" | $tg -t 7 >/dev/null
check "text from stdin" '/botT0KEN/sendMessage {"chat_id": "-100111", "message_thread_id": "7", "text": "from stdin"}'

$tg --html "<b>x</b>" >/dev/null
check "--html" '/botT0KEN/sendMessage {"chat_id": "-100111", "parse_mode": "HTML", "text": "<b>x</b>"}'

print "payload" > "$work/a file;1.log"
$tg -t 7 --file "$work/a file;1.log" "@not-a-file" >/dev/null
check "--file with caption" '/botT0KEN/sendDocument {"caption": "@not-a-file", "chat_id": "-100111", "document": "<file a file;1.log>", "message_thread_id": "7"}'

$tg --audio "$work/a file;1.log" </dev/null >/dev/null
check "--audio without caption" '/botT0KEN/sendAudio {"audio": "<file a file;1.log>", "chat_id": "-100111"}'

fails "API error is a non-zero exit" $tg "boom"
fails "unknown chat name" $tg -c nope "x"
fails "no text" $tg </dev/null
fails "unknown option" $tg --wat "x"

$scripts/tg-send.sh -100444 "plain" >/dev/null
check "tg-send.sh" '/botT0KEN/sendMessage {"chat_id": "-100444", "text": "plain"}'

$scripts/tg-send-thread.sh -100444 9 "threaded" HTML >/dev/null
check "tg-send-thread.sh" '/botT0KEN/sendMessage {"chat_id": "-100444", "message_thread_id": "9", "parse_mode": "HTML", "text": "threaded"}'

$scripts/tg-send-thread.sh -100444 9 "-starts with a dash" >/dev/null
check "tg-send-thread.sh, text starting with a dash" '/botT0KEN/sendMessage {"chat_id": "-100444", "message_thread_id": "9", "text": "-starts with a dash"}'

$scripts/tg-send-audio.sh -100444 9 "$work/a file;1.log" "cap" >/dev/null
check "tg-send-audio.sh" '/botT0KEN/sendAudio {"audio": "<file a file;1.log>", "caption": "cap", "chat_id": "-100444", "message_thread_id": "9"}'

fails "tg-send-thread.sh without a chat id" $scripts/tg-send-thread.sh "" 9 "x"

print "PASS ($n checks)"
