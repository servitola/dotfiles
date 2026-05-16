#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10", "numpy>=1.24"]
# ///
"""Texture fill: replace a region with sampled patches from elsewhere.

Use when AI inpaint refuses to remove a region — the model keeps
redrawing the unwanted content. Pick a clean source patch from the
same image and tile it onto the target with random y-offset to break
visible repetition.

  patch_fill.py --input in.png --output out.png \
    --target X,Y,W,H --sample X,Y,W,H --feather 8
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def bbox(s):
    try: return tuple(int(v) for v in s.split(","))
    except ValueError: sys.exit(f"bbox must be X,Y,W,H: {s!r}")

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--target", required=True, metavar="X,Y,W,H")
    p.add_argument("--sample", required=True, metavar="X,Y,W,H")
    p.add_argument("--feather", type=int, default=0)
    p.add_argument("--blur", type=float, default=1.0)
    p.add_argument("--seed", type=int, default=0)
    a = p.parse_args()
    if not a.input.exists(): sys.exit(f"not found: {a.input}")
    src = Image.open(a.input).convert("RGB")
    tx, ty, tw, th = bbox(a.target)
    sx, sy, sw, sh = bbox(a.sample)
    arr = np.array(src.crop((sx, sy, sx+sw, sy+sh)))
    rng = np.random.default_rng(a.seed)
    out = np.zeros((th, tw, 3), dtype=np.uint8)
    for x in range(0, tw, sw):
        yo = int(rng.integers(0, max(1, sh - 1)))
        col = np.tile(arr, (th // sh + 2, 1, 1))[yo:yo + th]
        w_real = min(sw, tw - x)
        out[:, x:x + w_real] = col[:, :w_real]
    fill = Image.fromarray(out)
    if a.blur > 0: fill = fill.filter(ImageFilter.GaussianBlur(radius=a.blur))
    if a.feather > 0:
        mask = Image.new("L", (tw, th), 0)
        ImageDraw.Draw(mask).rectangle([a.feather, a.feather, tw - a.feather, th - a.feather], fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(radius=a.feather))
    else:
        mask = Image.new("L", (tw, th), 255)
    region = src.crop((tx, ty, tx + tw, ty + th))
    src.paste(Image.composite(fill, region, mask), (tx, ty))
    a.output.parent.mkdir(parents=True, exist_ok=True)
    src.save(a.output)
    print(f"OK: {a.output}")

if __name__ == "__main__": main()
