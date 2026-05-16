#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10"]
# ///
"""Build an inpaint mask from primitives. See SKILL.md for full docs.

--shape [op:]kind:coords  where op=add|sub, kind=rect|ellipse|arch|ring.
Refinements: --shift DX,DY  --grow N  --shrink N  --feather N
Reuse last mask: --from-mask /tmp/_last_mask.png  (auto-cached after each run).
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

CACHE = Path("/tmp/_last_mask.png")

def res(p, dim): return round(float(p[:-1]) / 100 * dim) if p.endswith("%") else int(p)

def parse_shape(spec, w, h):
    parts = spec.split(":")
    op = parts.pop(0) if parts and parts[0] in ("add", "sub") else "add"
    if len(parts) != 2: sys.exit(f"bad shape {spec!r}")
    kind, raw = parts[0].lower(), parts[1].split(",")
    nums = [res(a.strip(), w if i % 2 == 0 else h) for i, a in enumerate(raw)]
    return op, kind, nums

def draw(c, kind, n, fill):
    d = ImageDraw.Draw(c)
    if kind == "rect": d.rectangle([n[0], n[1], n[0]+n[2], n[1]+n[3]], fill=fill)
    elif kind == "ellipse": d.ellipse([n[0]-n[2], n[1]-n[3], n[0]+n[2], n[1]+n[3]], fill=fill)
    elif kind == "arch":
        x, y, w, h = n; r = w // 2
        d.rectangle([x, y+r, x+w, y+h], fill=fill)
        d.pieslice([x, y, x+w, y+2*r], 180, 360, fill=fill)
    elif kind == "ring":
        d.ellipse([n[0]-n[2], n[1]-n[2], n[0]+n[2], n[1]+n[2]], fill=fill)
        d.ellipse([n[0]-n[3], n[1]-n[3], n[0]+n[3], n[1]+n[3]], fill=0 if fill else 255)
    else: sys.exit(f"unknown kind: {kind!r}")

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--like", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--shape", action="append", default=[])
    p.add_argument("--from-mask", type=Path, dest="from_mask")
    p.add_argument("--shift"); p.add_argument("--grow", type=int, default=0)
    p.add_argument("--shrink", type=int, default=0); p.add_argument("--feather", type=int, default=4)
    p.add_argument("--preview", type=Path); p.add_argument("--no-cache", action="store_true")
    a = p.parse_args()
    if not a.like.exists(): sys.exit(f"not found: {a.like}")
    if not a.shape and not a.from_mask: sys.exit("need --shape or --from-mask")
    with Image.open(a.like) as s: w, h = s.size
    if a.from_mask:
        with Image.open(a.from_mask) as m:
            mask = m.convert("L").resize((w, h)) if m.size != (w, h) else m.convert("L")
    else: mask = Image.new("L", (w, h), 0)
    for spec in a.shape:
        op, kind, nums = parse_shape(spec, w, h)
        draw(mask, kind, nums, 255 if op == "add" else 0)
    if a.shift:
        dx, dy = (int(v) for v in a.shift.split(","))
        t = Image.new("L", (w, h), 0); t.paste(mask, (dx, dy)); mask = t
    if a.grow or a.shrink:
        mask = mask.point(lambda v: 255 if v >= 128 else 0)
        if a.grow: mask = mask.filter(ImageFilter.MaxFilter(a.grow*2+1))
        if a.shrink: mask = mask.filter(ImageFilter.MinFilter(a.shrink*2+1))
    if a.feather > 0: mask = mask.filter(ImageFilter.GaussianBlur(a.feather))
    a.output.parent.mkdir(parents=True, exist_ok=True); mask.save(a.output)
    if not a.no_cache: mask.save(CACHE)
    print(f"OK: {a.output} ({w}x{h})")
    if a.preview:
        with Image.open(a.like) as s: base = s.convert("RGB")
        red = Image.new("RGB", base.size, (255, 0, 0))
        prev = Image.blend(base, Image.composite(red, base, mask).convert("RGB"), 0.55)
        a.preview.parent.mkdir(parents=True, exist_ok=True); prev.save(a.preview)
        print(f"PREVIEW: {a.preview}")

if __name__ == "__main__": main()
