#!/bin/zsh

VENV=~/.venv/tts
VOICES_DIR=~/.local/share/piper-voices
RU_MODEL="$VOICES_DIR/ru_RU-irina-medium.onnx"
VOICES_BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/irina/medium"

echo
echo "🔊 Setting up TTS (Piper)..."

# The shim it registers lives in $DIR_LITELLM, a separate repository a fresh
# Mac may not have; without it every step below fails and the old ending still
# said "TTS ready".
if [[ ! -d "${DIR_LITELLM:?}" ]]; then
    echo "  * Skip: no $DIR_LITELLM (DIR_LITELLM in constants.env)"
    return 0
fi

if [[ ! -d "$VENV" ]]; then
    uv venv "$VENV" --python 3.11 --quiet
fi

"$VENV/bin/uv" pip install --upgrade piper-tts 2>&1 | grep -v "^warning" | grep -E "(Installing|Updated|Already)" || true

mkdir -p "$VOICES_DIR"

if [[ ! -f "$RU_MODEL" ]]; then
    echo "  Downloading Russian voice model (~60MB)..."
    curl -fsSL -o "$RU_MODEL" "$VOICES_BASE/ru_RU-irina-medium.onnx"
    curl -fsSL -o "$RU_MODEL.json" "$VOICES_BASE/ru_RU-irina-medium.onnx.json"
fi

PLIST_SRC="${DIR_LITELLM:?}/piper-shim/com.servitola.piper-shim.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.servitola.piper-shim.plist"

if [[ ! -f "$PLIST_DST" ]]; then
    echo "  Registering piper-shim with launchd..."
    cp "$PLIST_SRC" "$PLIST_DST"
    launchctl load "$PLIST_DST"
else
    launchctl unload "$PLIST_DST" 2>/dev/null || true
    cp "$PLIST_SRC" "$PLIST_DST"
    launchctl load "$PLIST_DST"
fi

echo "✅ TTS ready (shim on :8177)"
