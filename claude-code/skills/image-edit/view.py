#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10"]
# ///
"""Downscaled preview for INSPECTION — read THIS into context, never the full-res file.

The deliverable image stays full-res on disk and is what you send to the user.
This makes a small (<=768 px) preview only so the agent can *look* and decide the
next tweak ("повыше", "правее", "листья поближе") cheaply. A 768 px preview costs
a fraction of a full-res image in vision tokens, and placement/composition is fully
legible at that size. Do ONE full-res Read as the final quality check before sending.

For cutouts (RGBA) the transparent areas are shown on a checkerboard so halos and
leftover background are visible in the preview.

  view.py --input result.png --output /tmp/preview.png        # default --max 768
  view.py --input cutout.png --output /tmp/preview.png --max 640
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
from PIL import Image


def _checkerboard(size, cell=16):
    w, h = size
    bg = Image.new("RGB", size, (200, 200, 200))
    dark = Image.new("RGB", (cell, cell), (160, 160, 160))
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            if (x // cell + y // cell) % 2:
                bg.paste(dark, (x, y))
    return bg


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--max", type=int, default=768, help="longest side of the preview (px)")
    a = p.parse_args()
    if not a.input.exists(): sys.exit(f"not found: {a.input}")

    with Image.open(a.input) as im:
        full = im.size
        im.thumbnail((a.max, a.max), Image.LANCZOS)
        if im.mode in ("RGBA", "LA", "P"):
            im = im.convert("RGBA")
            board = _checkerboard(im.size)
            board.paste(im, (0, 0), im)
            out = board
        else:
            out = im.convert("RGB")
        a.output.parent.mkdir(parents=True, exist_ok=True)
        out.save(a.output)
    print(f"OK: {a.output} ({out.size[0]}x{out.size[1]} preview of {full[0]}x{full[1]})")


if __name__ == "__main__": main()
