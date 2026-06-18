#!/bin/bash
# Open the selected video(s) on the LG TV via the lgtv audiosync daemon
# (video on the TV, sound synced on the Mac). The daemon (LaunchAgent) runs the
# whole playsync pipeline in its own process, so playback survives this action.
#
# Accepts files AND folders, and any multi-selection:
#   • one video file       → /play  (single)
#   • a folder, or several  → /playlist: the daemon plays them one after
#     items / files           another (auto-advance on end; ◄◄/►► seek;
#                              🔴/🔵 on the TV remote = prev/next file).
# Folders are walked recursively; entries are sorted by path; hidden files and
# non-video files are skipped. (Filenames containing newlines are not handled —
# extremely rare for video and not worth the complexity.)
notify() { /usr/bin/osascript -e "display notification \"$2\" with title \"📺 Open on TV\" subtitle \"$1\"" >/dev/null 2>&1; }

is_video() {
  case "$(printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]')" in
    mp4|mkv|avi|mov|m4v|webm|wmv|flv|ts|mts|m2ts|mpg|mpeg|3gp|ogv|divx) return 0 ;;
    *) return 1 ;;
  esac
}

[ $# -gt 0 ] || exit 0

# ── collect every video in the selection (files + folder contents) ──────────
files=()
for arg in "$@"; do
  if [ -d "$arg" ]; then
    while IFS= read -r f; do
      case "$(/usr/bin/basename "$f")" in .*) continue ;; esac   # skip dotfiles
      is_video "$f" && files+=("$f")
    done < <(/usr/bin/find "$arg" -type f | LC_ALL=C sort)
  elif [ -f "$arg" ]; then
    is_video "$arg" && files+=("$arg")
  fi
done

n=${#files[@]}
if [ "$n" -eq 0 ]; then
  notify "не видеофайлов" "$(/usr/bin/basename "$1")"
  exit 0
fi

# ── hand the daemon a single file (/play) or an ordered playlist (/playlist) ─
CTL="http://127.0.0.1:8202"
if [ "$n" -eq 1 ]; then
  endpoint="/play"
  body=$(/usr/bin/python3 -c 'import json,sys;print(json.dumps({"source":sys.argv[1]}))' "${files[0]}")
  label="$(/usr/bin/basename "${files[0]}")"
else
  endpoint="/playlist"
  body=$(/usr/bin/python3 -c 'import json,sys;print(json.dumps({"sources":sys.argv[1:]}))' "${files[@]}")
  label="$n файлов"
fi

if /usr/bin/curl -fsS -m 6 -X POST "$CTL$endpoint" \
     -H 'Content-Type: application/json' -d "$body" >/dev/null 2>&1; then
  notify "готовлю…" "$label"
else
  notify "audiosync офлайн — запусти LaunchAgent" "ошибка"
fi
