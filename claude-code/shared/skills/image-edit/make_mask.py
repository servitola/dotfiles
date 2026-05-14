#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10"]
# ///
"""Build an inpaint mask from geometric primitives.

White pixels = repaint. Black pixels = preserve. The mask is sized to
match the reference image so it can be passed directly to
`edit_inpaint.py --mask` or `edit_fal_fill.py --mask`.

Each --add SHAPE unions the shape into the white area; each --sub SHAPE
subtracts it. Shapes are evaluated left-to-right in command-line order.
Feathering blurs the boundary so the inpaint blends without seams.

Shapes (coords in input pixels; use `%` suffix for percent of image):
  rect:x,y,w,h            axis-aligned rectangle
  ellipse:cx,cy,rx,ry     ellipse centred at cx,cy
  arch:x,y,w,h            rectangle with semicircular top (mirror shape)
  ring:cx,cy,r_out,r_in   annulus, r_out > r_in

Examples:

  # Repaint the green frame around an arched mirror (the ring between an
  # outer arch and an inner arch). Soft 6 px feather for clean blend.
  make_mask.py --like input.jpg --output /tmp/m.png --feather 6 \
    --add arch:140,60,520,720 \
    --sub arch:200,120,400,600

  # Repaint the upper third of the mirror (where the neon caption lives)
  make_mask.py --like input.jpg --output /tmp/m.png --feather 4 \
    --add rect:200,120,400,200

  # Preview before spending a paid inpaint call
  make_mask.py --like input.jpg --output /tmp/m.png --add arch:140,60,520,720 \
    --preview /tmp/preview.png
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


def parse_shape(spec: str, w: int, h: int) -> tuple[str, list[int]]:
    if ":" not in spec:
        sys.exit(f"shape must be 'kind:args', got: {spec!r}")
    kind, args = spec.split(":", 1)
    try:
        nums = [_resolve(piece.strip(), w if i % 2 == 0 else h)
                for i, piece in enumerate(args.split(","))]
    except ValueError as exc:
        sys.exit(f"bad numbers in shape {spec!r}: {exc}")
    return kind.strip().lower(), nums


def _resolve(piece: str, dim: int) -> int:
    if piece.endswith("%"):
        return round(float(piece[:-1]) / 100.0 * dim)
    return int(piece)


def draw_shape(canvas: Image.Image, kind: str, nums: list[int], fill: int) -> None:
    d = ImageDraw.Draw(canvas)
    if kind == "rect":
        x, y, w, h = _require(nums, 4, "rect")
        d.rectangle([x, y, x + w, y + h], fill=fill)
    elif kind == "ellipse":
        cx, cy, rx, ry = _require(nums, 4, "ellipse")
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill)
    elif kind == "arch":
        x, y, w, h = _require(nums, 4, "arch")
        r = w // 2
        d.rectangle([x, y + r, x + w, y + h], fill=fill)
        d.pieslice([x, y, x + w, y + 2 * r], start=180, end=360, fill=fill)
    elif kind == "ring":
        cx, cy, ro, ri = _require(nums, 4, "ring")
        d.ellipse([cx - ro, cy - ro, cx + ro, cy + ro], fill=fill)
        d.ellipse([cx - ri, cy - ri, cx + ri, cy + ri], fill=0 if fill else 255)
    else:
        sys.exit(f"unknown shape kind: {kind!r}")


def _require(nums: list[int], n: int, kind: str) -> list[int]:
    if len(nums) != n:
        sys.exit(f"{kind} needs {n} numbers, got {len(nums)}: {nums}")
    return nums


def build_mask(like: Path, ops: Iterable[tuple[str, str, list[int]]], feather: int) -> Image.Image:
    with Image.open(like) as src:
        w, h = src.size
    mask = Image.new("L", (w, h), 0)
    for op, kind, nums in ops:
        fill = 255 if op == "add" else 0
        draw_shape(mask, kind, nums, fill)
    if feather > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(radius=feather))
    return mask


def make_preview(like: Path, mask: Image.Image, out: Path) -> None:
    with Image.open(like) as src:
        base = src.convert("RGB")
    overlay = Image.new("RGB", base.size, (255, 0, 0))
    blended = Image.composite(overlay, base, mask).convert("RGB")
    preview = Image.blend(base, blended, 0.55)
    out.parent.mkdir(parents=True, exist_ok=True)
    preview.save(out)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--like", required=True, type=Path, help="reference image — mask is sized to match")
    p.add_argument("--output", required=True, type=Path, help="mask PNG to write")
    p.add_argument("--add", action="append", default=[], metavar="SHAPE",
                   help="union shape into mask (white). Repeatable.")
    p.add_argument("--sub", action="append", default=[], metavar="SHAPE",
                   help="subtract shape from mask (black). Repeatable.")
    p.add_argument("--feather", type=int, default=4, help="gaussian blur radius on edges (px). Default 4.")
    p.add_argument("--preview", type=Path, help="also write an overlay PNG: input tinted red where mask is white")
    args = p.parse_args()

    if not args.like.exists():
        sys.exit(f"reference image not found: {args.like}")
    if not args.add and not args.sub:
        sys.exit("at least one --add or --sub shape required")

    with Image.open(args.like) as src:
        w, h = src.size

    ops: list[tuple[str, str, list[int]]] = []
    raw = [("add", s) for s in args.add] + [("sub", s) for s in args.sub]
    raw_in_argv_order = _interleave_in_argv_order(args.add, args.sub)
    for op, spec in raw_in_argv_order:
        kind, nums = parse_shape(spec, w, h)
        ops.append((op, kind, nums))

    mask = build_mask(args.like, ops, args.feather)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    mask.save(args.output)
    print(f"OK: {args.output} ({w}x{h}, {len(ops)} shapes, feather={args.feather})")

    if args.preview:
        make_preview(args.like, mask, args.preview)
        print(f"PREVIEW: {args.preview}")


def _interleave_in_argv_order(adds: list[str], subs: list[str]) -> list[tuple[str, str]]:
    """Reconstruct CLI order so subtractions occur after their adds.

    argparse with action="append" loses interleaving. We reparse sys.argv
    to recover the order users typed.
    """
    order: list[tuple[str, str]] = []
    add_iter, sub_iter = iter(adds), iter(subs)
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--add" and i + 1 < len(args):
            order.append(("add", next(add_iter)))
            i += 2
        elif args[i] == "--sub" and i + 1 < len(args):
            order.append(("sub", next(sub_iter)))
            i += 2
        elif args[i].startswith("--add="):
            order.append(("add", next(add_iter)))
            i += 1
        elif args[i].startswith("--sub="):
            order.append(("sub", next(sub_iter)))
            i += 1
        else:
            i += 1
    return order


if __name__ == "__main__":
    main()
