#!/usr/bin/env bash
# One-time setup: a single venv with pinned deps + a grand-piano soundfont.
set -e
VENV="${PIANO_VENV:-$HOME/.cache/piano-venv}"
SF2="$HOME/.cache/MuseScore_General.sf2"

if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install -q -U pip
# numpy<2 first so nothing drags in numpy 2 (breaks scipy/librosa/basic-pitch).
"$VENV/bin/pip" install -q "numpy<2" "scipy<1.13" "setuptools<81"
"$VENV/bin/pip" install -q "basic-pitch[onnx]" opencv-python-headless pretty_midi \
  librosa music21 verovio cairosvg pypdf pymupdf PyGuitarPro
echo "venv ready: $VENV"

if [ ! -f "$SF2" ]; then
  echo "fetching grand-piano soundfont (~215 MB)…"
  curl -sL -o "$SF2" \
    "https://ftp.osuosl.org/pub/musescore/soundfont/MuseScore_General/MuseScore_General.sf2" \
    || echo "soundfont download failed — set SF2 manually for Phase 5"
fi
echo "soundfont: $SF2"

command -v fluidsynth >/dev/null || echo "note: install fluidsynth for Phase 5 render (brew install fluid-synth)"
"$VENV/bin/python" -c "import cairosvg" 2>/dev/null \
  || echo "note: cairosvg needs system Cairo — brew install cairo, then use DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib"
