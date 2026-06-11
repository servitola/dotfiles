#!/usr/bin/env python3
"""Convert an MP4 clip to a high-quality looping GIF via ffmpeg palettegen.

Only needed when the user explicitly wants a real .gif file. For Telegram,
sending the MP4 through send_animation is better (smaller, auto-loops).

  to_gif.py --input clip.mp4 --output clip.gif --fps 15 --width 480
"""
from __future__ import annotations
import argparse, subprocess, sys, tempfile
from pathlib import Path


def convert(inp: Path, out: Path, fps: int, width: int) -> None:
    vf = f"fps={fps},scale={width}:-1:flags=lanczos"
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        palette = tmp.name
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(inp),
                    "-vf", f"{vf},palettegen=stats_mode=diff", palette], check=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(inp), "-i", palette,
                    "-lavfi", f"{vf} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=3",
                    "-loop", "0", str(out)], check=True)
    print(f"OK: {out} ({out.stat().st_size // 1024} KB)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True, type=Path)
    ap.add_argument("--output", required=True, type=Path)
    ap.add_argument("--fps", default=15, type=int)
    ap.add_argument("--width", default=480, type=int)
    a = ap.parse_args()
    if not a.input.exists():
        sys.exit(f"input not found: {a.input}")
    convert(a.input, a.output, a.fps, a.width)


if __name__ == "__main__":
    main()
