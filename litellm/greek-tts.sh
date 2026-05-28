#!/usr/bin/env bash
# greek-tts — generate Greek MP3 from a JSON spec via LiteLLM proxy + Azure TTS.
#
# Reads JSON from stdin describing one or more utterances and emits a single
# MP3. Used by the `greek-tts` skill, but standalone-friendly.
#
# Input shape — JSON array, one object per turn:
#   [
#     {"voice": "el-GR-NestorasNeural", "text": "Άκου..."},
#     {"voice": "el-GR-AthinaNeural",   "text": "Γιατί;", "rate": "-20%"}
#   ]
#
# Fields:
#   voice  — required. Azure neural voice id (e.g. el-GR-NestorasNeural,
#            el-GR-AthinaNeural). Any Azure neural voice works.
#   text   — required. Plain text. The script wraps it in SSML so the rate
#            knob below has effect; do not pre-wrap unless you want full
#            control (see "raw SSML" below).
#   rate   — optional. SSML prosody rate, default "$RATE_DEFAULT" (slightly
#            slower than natural — feels good for learning material).
#            Examples: "-25%", "+10%", "slow", "x-slow", "fast".
#   ssml   — optional bool. If true, "text" is treated as raw SSML and passed
#            through unchanged (voice/rate fields ignored). Use this for
#            multi-style or styled output not expressible via rate alone.
#
# Output: writes MP3 to the path given as $1 (or to ./greek-out.mp3 by default).
# Inter-turn silence: 400 ms.
#
# Caching: every generated turn is cached at ~/.cache/greek-tts/<sha256>.mp3
# keyed by (voice + rate + text + ssml-or-not). Rerun is free.
#
# Examples:
#   echo '[{"voice":"el-GR-NestorasNeural","text":"Καλημέρα!"}]' \
#     | ~/projects/dotfiles/litellm/greek-tts.sh hello.mp3
#
#   jq -n '[
#     {"voice":"el-GR-NestorasNeural","text":"Άκου..."},
#     {"voice":"el-GR-AthinaNeural","text":"Γιατί;"}
#   ]' | ~/projects/dotfiles/litellm/greek-tts.sh dialogue.mp3

set -euo pipefail

BASE="${LITELLM_BASE:-http://localhost:4000}"
KEY="${LITELLM_MASTER_KEY:-sk-local-workbot}"
MODEL="${MODEL:-tts-azure}"
RATE_DEFAULT="${RATE_DEFAULT:--10%}"
SILENCE_MS="${SILENCE_MS:-400}"
CACHE_DIR="${CACHE_DIR:-$HOME/.cache/greek-tts}"

OUT="${1:-greek-out.mp3}"
mkdir -p "$CACHE_DIR" "$(dirname "$OUT")"
WORK="$(mktemp -d -t greek-tts.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

SPEC="$WORK/spec.json"
cat > "$SPEC"
if ! jq -e 'type == "array" and length > 0' "$SPEC" >/dev/null 2>&1; then
  echo "greek-tts: stdin must be a non-empty JSON array of turns" >&2
  exit 2
fi

# 24 kHz mono silence between turns, generated once.
SILENCE="$WORK/silence.mp3"
ffmpeg -hide_banner -loglevel error -y -f lavfi \
  -i "anullsrc=r=24000:cl=mono" \
  -t "$(awk -v ms="$SILENCE_MS" 'BEGIN{print ms/1000}')" \
  -c:a libmp3lame -b:a 48k "$SILENCE"

LIST="$WORK/list.txt"
: > "$LIST"

n=$(jq 'length' "$SPEC")
i=0
while [ "$i" -lt "$n" ]; do
  turn=$(jq -c ".[$i]" "$SPEC")
  voice=$(jq -r '.voice // empty' <<<"$turn")
  text=$(jq -r '.text  // empty' <<<"$turn")
  rate=$(jq -r '.rate  // empty' <<<"$turn")
  ssml_flag=$(jq -r '.ssml // false' <<<"$turn")
  [ -n "$voice" ] || { echo "turn $i: missing voice" >&2; exit 2; }
  [ -n "$text"  ] || { echo "turn $i: missing text"  >&2; exit 2; }
  [ -n "$rate"  ] || rate="$RATE_DEFAULT"

  # Build the payload Azure expects. When ssml=true the caller takes full
  # control. Otherwise wrap plain text in <speak><voice><prosody> so we get
  # the requested rate.
  if [ "$ssml_flag" = "true" ]; then
    payload="$text"
  else
    # SSML escaping: & < > " ' must be entitized inside text nodes.
    esc=$(printf '%s' "$text" \
      | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' \
            -e 's/"/\&quot;/g' -e "s/'/\\&apos;/g")
    payload="<speak version=\"1.0\" xml:lang=\"el-GR\"><voice name=\"$voice\"><prosody rate=\"$rate\">$esc</prosody></voice></speak>"
  fi

  hash=$(printf '%s\n%s' "$MODEL" "$payload" | shasum -a 256 | awk '{print $1}')
  cached="$CACHE_DIR/$hash.mp3"
  preview="${text:0:60}"
  printf '%02d %s (%s, rate=%s): %s\n' "$i" "$voice" "$MODEL" "$rate" "${preview}…" >&2

  if [ ! -s "$cached" ]; then
    body=$(jq -n --arg m "$MODEL" --arg v "$voice" --arg t "$payload" \
      '{model:$m, voice:$v, input:$t}')
    http=$(curl -sS -o "$cached.tmp" -w '%{http_code}' \
      "$BASE/v1/audio/speech" \
      -H "Authorization: Bearer $KEY" \
      -H "Content-Type: application/json" \
      -d "$body")
    if [ "$http" != "200" ]; then
      echo "TTS failed ($http):" >&2; cat "$cached.tmp" >&2; echo >&2
      rm -f "$cached.tmp"; exit 1
    fi
    mv "$cached.tmp" "$cached"
  else
    echo "  ✓ cache hit" >&2
  fi

  printf "file '%s'\n" "$cached" >> "$LIST"
  # Inter-turn silence — skip after the last turn.
  if [ "$((i + 1))" -lt "$n" ]; then
    printf "file '%s'\n" "$SILENCE" >> "$LIST"
  fi
  i=$(( i + 1 ))
done

ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$LIST" \
  -c:a libmp3lame -b:a 48k -ar 24000 -ac 1 "$OUT"

dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT")
printf '✔ %s  (%.1fs, %s)\n' "$OUT" "$dur" "$(du -h "$OUT" | cut -f1)" >&2
echo "$OUT"
