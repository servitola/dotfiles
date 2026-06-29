#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10", "numpy>=1.24"]
# ///
"""Place a cutout (RGBA) onto a background — the "вписать вырезку на стену" step.

Replaces the hand-written PIL composite that gets re-typed every iteration:
resize the subject with LANCZOS, build the canvas (a real photo, a flat colour,
or a colour sampled from a wall region of a source photo), paste with alpha.

Background — pick ONE:
  --background room.jpg              use a photo as the canvas (its size by default)
  --bg-color 172,158,142            flat colour canvas (needs --size)
  --bg-from room.jpg --bg-sample X,Y,W,H   sample mean wall colour from a region

Subject size & position:
  --scale 0.8        subject height = 0.8 * canvas height (default)
  --height 900       subject height in px (overrides --scale)
  --pos center       center | bottom | "CX,CY" (subject centre in px)

  composite.py --subject кашпо.png --background room.jpg \
    --scale 0.7 --pos bottom --output final.png --preview /tmp/preview.png

  composite.py --subject монстера.png --bg-from room.jpg --bg-sample 40,40,120,120 \
    --size 1280,1190 --scale 0.85 --output final.png
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
import numpy as np
from PIL import Image


def _ints(s, n, name):
    try:
        v = tuple(int(x) for x in s.split(","))
    except ValueError:
        sys.exit(f"{name} must be {n} comma-separated ints: {s!r}")
    if len(v) != n: sys.exit(f"{name} needs {n} values, got {len(v)}: {s!r}")
    return v


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--subject", required=True, type=Path, help="RGBA cutout to place")
    p.add_argument("--background", type=Path, help="photo used as the canvas")
    p.add_argument("--bg-color", help="flat canvas colour R,G,B (needs --size)")
    p.add_argument("--bg-from", type=Path, help="photo to sample a wall colour from")
    p.add_argument("--bg-sample", help="region X,Y,W,H in --bg-from to average")
    p.add_argument("--size", help="canvas size W,H (for colour canvases)")
    p.add_argument("--scale", type=float, default=0.8,
                   help="subject height as fraction of canvas height; default 0.8")
    p.add_argument("--height", type=int, help="subject height in px (overrides --scale)")
    p.add_argument("--pos", default="center", help="center | bottom | CX,CY")
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--preview", type=Path, help="also write a <=768px preview here")
    a = p.parse_args()
    if not a.subject.exists(): sys.exit(f"not found: {a.subject}")

    subject = Image.open(a.subject).convert("RGBA")

    # --- build the canvas ---
    if a.background:
        if not a.background.exists(): sys.exit(f"not found: {a.background}")
        canvas = Image.open(a.background).convert("RGB")
        if a.size:
            canvas = canvas.resize(_ints(a.size, 2, "--size"), Image.LANCZOS)
    elif a.bg_from and a.bg_sample:
        if not a.bg_from.exists(): sys.exit(f"not found: {a.bg_from}")
        if not a.size: sys.exit("--bg-from/--bg-sample needs --size")
        x, y, w, h = _ints(a.bg_sample, 4, "--bg-sample")
        src = Image.open(a.bg_from).convert("RGB")
        patch = np.asarray(src.crop((x, y, x + w, y + h)))
        color = tuple(int(c) for c in patch.reshape(-1, 3).mean(axis=0))
        canvas = Image.new("RGB", _ints(a.size, 2, "--size"), color)
    elif a.bg_color:
        if not a.size: sys.exit("--bg-color needs --size")
        canvas = Image.new("RGB", _ints(a.size, 2, "--size"), _ints(a.bg_color, 3, "--bg-color"))
    else:
        sys.exit("pick a background: --background | --bg-color | --bg-from+--bg-sample")

    cw, ch = canvas.size

    # --- scale the subject (preserve aspect) ---
    target_h = a.height if a.height else max(1, int(round(a.scale * ch)))
    ratio = target_h / subject.height
    subject = subject.resize((max(1, round(subject.width * ratio)), target_h), Image.LANCZOS)
    sw, sh = subject.size

    # --- position ---
    if a.pos == "center":
        cx, cy = cw // 2, ch // 2
    elif a.pos == "bottom":
        cx, cy = cw // 2, ch - sh // 2
    else:
        cx, cy = _ints(a.pos, 2, "--pos")
    x0, y0 = cx - sw // 2, cy - sh // 2

    out = canvas.convert("RGBA")
    out.alpha_composite(subject, (x0, y0))
    out = out.convert("RGB")

    a.output.parent.mkdir(parents=True, exist_ok=True)
    out.save(a.output)
    print(f"OK: {a.output} ({cw}x{ch}, subject {sw}x{sh} @ {x0},{y0})")

    if a.preview:
        prev = out.copy(); prev.thumbnail((768, 768), Image.LANCZOS)
        a.preview.parent.mkdir(parents=True, exist_ok=True)
        prev.save(a.preview)
        print(f"preview: {a.preview} ({prev.size[0]}x{prev.size[1]})")


if __name__ == "__main__": main()
