#!/bin/zsh
# Extracts audio track from video file(s) as 192kbps MP3 next to the source.

notify() {
    osascript -e "display notification \"$1\" with title \"Video to MP3\"" >/dev/null 2>&1
}

ffmpeg='/opt/homebrew/bin/ffmpeg'
[ -x "$ffmpeg" ] || ffmpeg='/usr/local/bin/ffmpeg'
if [ ! -x "$ffmpeg" ]; then
    notify "ffmpeg not found"
    exit 1
fi

ok=0
fail=0
for src in "$@"; do
    [ -f "$src" ] || { fail=$((fail+1)); continue; }
    dir="$(dirname "$src")"
    base="$(basename "$src")"
    name="${base%.*}"
    out="$dir/$name.mp3"
    # avoid overwrite
    i=1
    while [ -f "$out" ]; do
        out="$dir/$name ($i).mp3"
        i=$((i+1))
    done
    if "$ffmpeg" -nostdin -loglevel error -y -i "$src" -vn -acodec libmp3lame -b:a 192k "$out" </dev/null; then
        ok=$((ok+1))
    else
        fail=$((fail+1))
    fi
done

if [ "$fail" -eq 0 ]; then
    notify "converted ${ok} file(s)"
else
    notify "converted ${ok}, failed ${fail}"
fi
