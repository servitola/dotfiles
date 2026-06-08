#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["gradio-client>=1.4", "Pillow>=10"]
# ///
"""Mask from natural-language description via Florence-2 (HF, free).

Falls back to grounded bbox if RES is unavailable. Cached to
/tmp/_last_mask.png. Refine with make_mask.py --from-mask …
"""
from __future__ import annotations
import argparse, ast, sys
from pathlib import Path
from gradio_client import Client, handle_file
from PIL import Image, ImageDraw, ImageFilter

SPACE = "gokaygokay/Florence-2"; CACHE = Path("/tmp/_last_mask.png")

def _parse(a):
    if isinstance(a, dict): return a
    try: return ast.literal_eval(a) if isinstance(a, str) else {}
    except (ValueError, SyntaxError): return {}

def _extract(parsed, *keys, inner):
    for k in keys:
        v = parsed.get(k)
        if isinstance(v, dict) and inner in v: return v[inner]
        if isinstance(v, list): return v
    return []

def detect(path, desc):
    img = handle_file(str(path))
    try: res = Client(SPACE).predict(image=img, task_prompt="Referring Expression Segmentation",
        text_input=desc, api_name="/process_image")
    except Exception as exc:
        print(f"[res failed: {exc}, fallback to grounding]", file=sys.stderr)
        res = Client(SPACE).predict(image=img, task_prompt="Caption to Phrase Grounding",
            text_input=desc, api_name="/process_image")
    parsed = _parse(res[0] if isinstance(res, (list, tuple)) and res else res)
    return (_extract(parsed, "<REFERRING_EXPRESSION_SEGMENTATION>", "<RES>", "polygons", inner="polygons"),
            _extract(parsed, "<CAPTION_TO_PHRASE_GROUNDING>", "bboxes", inner="bboxes"))


def rasterize(size, polys, boxes):
    m = Image.new("L", size, 0); d = ImageDraw.Draw(m)
    for group in polys or []:
        for poly in (group if group and isinstance(group[0], list) else [group]):
            pts = [(float(poly[i]), float(poly[i+1])) for i in range(0, len(poly)-1, 2)]
            if len(pts) >= 3: d.polygon(pts, fill=255)
    for box in boxes or []:
        d.rectangle([float(v) for v in box[:4]], fill=255)
    return m


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--like", required=True, type=Path)
    p.add_argument("--describe", required=True)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--feather", type=int, default=4)
    p.add_argument("--preview", type=Path)
    a = p.parse_args()
    if not a.like.exists(): sys.exit(f"not found: {a.like}")
    with Image.open(a.like) as im: w, h = im.size
    polys, boxes = detect(a.like, a.describe)
    if not polys and not boxes: sys.exit(f"no region matched: {a.describe!r}")
    mask = rasterize((w, h), polys, boxes)
    if a.feather > 0: mask = mask.filter(ImageFilter.GaussianBlur(a.feather))
    a.output.parent.mkdir(parents=True, exist_ok=True); mask.save(a.output); mask.save(CACHE)
    print(f"OK: {a.output} ({w}x{h}, {len(polys)} polys, {len(boxes)} boxes)")
    if a.preview:
        with Image.open(a.like) as s: base = s.convert("RGB")
        red = Image.new("RGB", base.size, (255, 0, 0))
        Image.blend(base, Image.composite(red, base, mask).convert("RGB"), 0.55).save(a.preview)
        print(f"PREVIEW: {a.preview}")

if __name__ == "__main__": main()
