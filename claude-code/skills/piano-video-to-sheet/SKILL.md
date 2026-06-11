---
name: piano-video-to-sheet
description: |
  Transcribe a Synthesia-style piano YouTube video (falling note bars on a virtual keyboard) into a clean MIDI, a real-grand-piano mp3, engraved sheet music (PDF + editable MusicXML), and a Guitar Pro (.gp5) file. Fuses audio transcription (Spotify basic-pitch) with computer-vision reading of the falling bars for accurate pitches and frame-accurate timing, adds audio-derived velocity dynamics and a sustain-pedal lane, then engraves with key/tempo detection.

  Use when: "разбери видео пианино в ноты", "пианино в ноты", "пианино в миди", "сделай ноты из видео", "ноты по видео с ютуба", "сделай midi из этого пианино", "видео в ноты", "сделай guitar pro из видео", "synthesia to midi", "piano video to sheet music", "transcribe this piano youtube video", "falling notes to midi", "youtube piano to pdf"
---

# Piano video → MIDI, mp3, sheet music, Guitar Pro

Turns a "falling notes" piano video (Synthesia / Patreon-style: glowing bars dropping onto a virtual keyboard, keys light up on strike) into musician-grade artifacts. Works because the video literally encodes the score — the bars are discrete and pitched by x-position, far more reliable than audio alone.

All steps run from the user's current topic folder and share intermediate files (`_audio.wav`, `_video.mp4`, `_raw.mid`, `_keymodel.json`, `_occ.npy`, `_notes.json`, `_warped.json`). Scripts live next to this file; `SKILL_DIR` is that directory.

## Phase 0 — Environment

One venv holds everything; the version pins matter (newer releases broke basic-pitch). Run once per machine:

```bash
bash SKILL_DIR/scripts/setup.sh        # creates ~/.cache/piano-venv, installs pinned deps
```

`cairosvg` needs the system Cairo library. If missing: `brew install cairo` (no sudo), then always prefix render/engrave commands with `DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib`. The setup script also fetches a sampled grand-piano soundfont to `~/.cache/MuseScore_General.sf2`.

Set `V=~/.cache/piano-venv/bin/python` for the commands below.

## Phase 1 — Download

```bash
yt-dlp -x --audio-format wav -o "_audio.%(ext)s" "<URL>"
yt-dlp -f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mp4 -o "_video.mp4" "<URL>"
```

Confirm the video is the right type before continuing: extract one mid-clip frame and look at it. Proceed only if you see a keyboard with falling bars and keys that glow on strike. If it is a real filmed performance (hands on a real piano, no falling bars), the CV steps do not apply — fall back to audio-only (Phase 2) and tell the user pitch accuracy will be lower.

## Phase 2 — Audio baseline (basic-pitch)

```bash
$V SKILL_DIR/scripts/transcribe.py _audio.wav _raw.mid
```

Produces `_raw.mid`: real pitches and rough timing, but extra notes. This is the pitch/harmony backbone.

## Phase 3 — Read the falling bars (computer vision)

```bash
$V SKILL_DIR/scripts/video_notes.py _video.mp4          # → _median.jpg, _keymodel.json, _occ.npy, _calib.png
```

This calibrates the 88-key geometry from a median frame (moving bars/hands average away, leaving a clean keyboard), then reads bar occupancy on a detection line just above the strike line.

Verify calibration visually: open `_calib.png` and check the green lines sit on the white-key gaps. Defaults assume a full 88-key keyboard spanning the frame width with the strike line near y≈360. If the layout differs, adjust the constants documented at the top of `video_notes.py` (key range, strike-line y, detection band) and rerun.

Then fuse audio + bars — read [references/method.md](references/method.md) for why this fusion is the heart of the skill (the glow blooms ±5 keys so it is unusable alone; the bars phantom only ±1–2 semitones; audio supplies clean pitch; bars supply frame-accurate onsets):

```bash
$V SKILL_DIR/scripts/fuse.py            # _raw.mid + _occ.npy → _notes.json + _fused.mid
```

## Phase 4 — Dynamics and pedal

```bash
$V SKILL_DIR/scripts/velocity_pedal.py  # → _final.mid (velocity from per-note audio energy + CC64 sustain)
```

Velocity comes from the spectral energy at each note's own frequency at its attack. The sustain pedal is inferred from the audio: between-note loudness barely dips when the pedal is held; sharp dips mark pedal lifts at harmony changes. Notes ring to the next lift; CC64 events are written for a real DAW.

## Phase 5 — Render with a real piano

```bash
DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib \
  fluidsynth -ni -g 0.7 -F _r.wav ~/.cache/MuseScore_General.sf2 _final.mid && \
  ffmpeg -y -i _r.wav -q:a 2 "<Song> - piano.mp3" && rm _r.wav
```

The sampled grand replaces the toy GM synth — the single biggest audible upgrade. Send the mp3.

## Phase 6 — Sheet music

```bash
DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib \
  $V SKILL_DIR/scripts/sheet.py _audio.wav "<Song>"   # reads _notes.json → score PDF + editable MusicXML + _warped.json
```

Beat-tracks the audio, warps the rubato performance onto an even beat grid, quantizes to 16ths, splits hands at middle C, detects the key, and respells enharmonics to fit it (flat keys get flats, not sharps — far fewer visible accidentals). Engraves with Verovio + Cairo.

Two known cosmetics, already handled in the script: Verovio renders the metronome glyph as an empty box, so tempo is written as bold text ("Andante · NNN BPM"); and the editable MusicXML uses music21's native tempo (no string surgery) so MuseScore opens it without a "corrupted" warning.

Send the PDF and the `.musicxml` (editable in MuseScore / flat.io).

## Phase 7 — Guitar Pro + cross-check

```bash
$V SKILL_DIR/scripts/guitarpro.py "<Song>"     # _warped.json (from Phase 6) → .gp5, then round-trip verifies
```

GP5 is a fretted format, so the piano is mapped onto octave-tuned strings (the tab looks unusual but pitch and playback are exact). The script writes the file, reads it back, and reports note-match against the source — expect 100%. Track names must be Latin (GP5 is cp1252; Cyrillic crashes the writer).

## Deliverables checklist

Before reporting done, confirm all five exist and send them: the cleaned **MIDI** (`_final.mid`, with velocity + CC64 pedal), the **real-piano mp3**, the **sheet PDF**, the **editable MusicXML**, and the **Guitar Pro .gp5** (with its round-trip match printed). If any phase was skipped (e.g. audio-only fallback for a non-Synthesia video), say so plainly.

## Talking to the user

Send artifacts as you finish each phase, plain-language captions, no internal file names. Offer the natural next refinements only if asked: lighter rhythm in dense bars, fingering, stereo piano placement. Keep the pipeline (git, scripts, venvs) invisible — describe results, not plumbing.
