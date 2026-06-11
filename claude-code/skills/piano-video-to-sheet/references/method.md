# Method notes: why the fusion works

Read this when tuning Phase 3 or when results look noisy.

## Three signals, three weaknesses

| Signal | Strength | Weakness |
|---|---|---|
| Audio (basic-pitch) | correct pitches, real key/harmony | extra notes (~3–4× too many onsets), rough timing |
| Key-glow (keys light on strike) | shows activity | glow **blooms ±5 semitones** sideways — cannot resolve which notes are in a chord. Unusable as a note source. |
| Falling bars | discrete, pitched by x, frame-accurate onset | phantom neighbours **±1–2 semitones** (bar edge leaks into the next key's window); sparkle particles; crystal texture splits one bar into several |

## What actually works

Read pitches from the audio, not the video. The winning recipe:

1. **Pitches and note set come from the audio** (basic-pitch). It has the real musical content — the pitch-class histogram of a real piece is uneven (tonic triad dominates); a near-uniform histogram is the telltale of CV noise.
2. **The bars confirm/deny each audio note and tighten its onset to the exact frame.** An audio note is kept if a bar is present at that key around that time (or if the note is long enough that occlusion likely hid it). This removes the audio's extra notes and snaps timing to 30 fps.

Measured on a real run: audio→video confirmation was 79%; pure-video extraction was ~20% precision; the fused result was clean and tonally coherent (key analysis confidence 0.95).

## CV calibration details

- **Median frame** over ~120 sampled frames erases moving bars/hands/glow and leaves a static keyboard for geometry. White-key separators are dark vertical valleys in a brightness profile sampled low on the keys (below the black keys). 51 valleys → 52 white keys → full 88-key piano; leftmost white = A0 (MIDI 21). Black keys sit on the white-white boundaries that are a whole step apart.
- **Sample the bars just above the strike line, not on it.** The strike-line halo (and the key glow) floods a band right at the keyboard with magenta and destroys resolution. A band ~15–45 px above the strike line catches the discrete bars cleanly. "Purpleness" = `min(B,R) − G` (magenta is high R+B, low G); reddish hands score ~0 and don't interfere.
- **Peak-picking vs window averaging:** window-averaging per key + spatial non-maximum suppression (kill a key if a ±1/±2 neighbour is stronger) beats raw peak-picking, which latches onto sparkle particles.
- Detected bars lead the actual strike by a few frames (bar reaches the detection band before the key). A global time shift (≈6 frames) aligns onsets to the audio; the fuse step re-snaps per note anyway.

## Dependency landmines (all pinned in setup.sh)

- `numpy<2` — scipy/librosa/basic-pitch all break on numpy 2.
- `scipy<1.13` — basic-pitch calls the removed `scipy.signal.gaussian`.
- `setuptools<81` — basic-pitch's resampy imports the removed `pkg_resources`.
- `basic-pitch[onnx]` + run with `--model-serialization onnx` (the default model path expects TensorFlow).
- Guitar Pro `.gp5` is **cp1252** — track/title strings must be Latin or the writer raises UnicodeEncodeError.
- Verovio's metronome note glyph renders as an empty box through Cairo — write tempo as plain bold text instead.
