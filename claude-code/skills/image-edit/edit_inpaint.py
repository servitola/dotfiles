#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["gradio-client>=1.4", "Pillow>=10"]
# ///
"""Inpaint via FLUX.1-Fill-dev HF Space (free). See SKILL.md.

White=repaint, black=preserve. Pass --mask PNG or --bbox x,y,w,h.
--variants N (1-4): N parallel calls with random seeds.
Outputs: <output>, <output_stem>-2.png, -3.png, …
"""
from __future__ import annotations
import argparse, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from gradio_client import Client, handle_file
from PIL import Image, ImageDraw

SPACE = "black-forest-labs/FLUX.1-Fill-dev"

def _bbox_mask(input_path, bbox):
    try: x, y, w, h = (int(v) for v in bbox.split(","))
    except ValueError: sys.exit(f"--bbox must be x,y,w,h ints, got: {bbox!r}")
    with Image.open(input_path) as src: size = src.size
    mask = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(mask).rectangle([x, y, x+w, y+h], fill=(255, 255, 255, 255))
    _, out = tempfile.mkstemp(prefix="inpaint_", suffix=".png")
    mask.save(out); Path(out).chmod(0o644); return Path(out)


def _extract(r):
    if isinstance(r, str): return r
    if isinstance(r, (list, tuple)):
        for it in r:
            p = _extract(it)
            if p: return p
    if isinstance(r, dict):
        for k in ("path", "image", "url", "value"):
            if k in r and (p := _extract(r[k])): return p
    return None


def _one(input_path, mask_path, prompt, w, h, idx):
    edit = {"background": handle_file(str(input_path)),
            "layers": [handle_file(str(mask_path))],
            "composite": handle_file(str(input_path)), "id": None}
    res = Client(SPACE).predict(edit_images=edit, prompt=prompt, seed=idx*1000+1,
        randomize_seed=True, width=w, height=h, guidance_scale=30.0,
        num_inference_steps=28, api_name="/infer")
    path = _extract(res)
    if not path: raise RuntimeError(f"unexpected result: {res!r}")
    return path


def inpaint(input_path, mask_path, prompt, output, variants):
    with Image.open(input_path) as im: w, h = im.size
    output.parent.mkdir(parents=True, exist_ok=True)
    paths = [output] + [output.with_name(f"{output.stem}-{i+1}{output.suffix}") for i in range(1, variants)]
    with ThreadPoolExecutor(max_workers=variants) as ex:
        futs = [ex.submit(_one, input_path, mask_path, prompt, w, h, i) for i in range(variants)]
        for dst, f in zip(paths, futs):
            shutil.copyfile(f.result(), dst); print(f"OK: {dst}")
    print(f"DONE: {len(paths)} variant(s)")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--prompt", required=True)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--variants", type=int, default=1, choices=range(1, 5), metavar="N")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--mask", type=Path); g.add_argument("--bbox")
    a = p.parse_args()
    if not a.input.exists(): sys.exit(f"input not found: {a.input}")
    if a.mask and not a.mask.exists(): sys.exit(f"mask not found: {a.mask}")
    inpaint(a.input, a.mask or _bbox_mask(a.input, a.bbox), a.prompt, a.output, a.variants)


if __name__ == "__main__": main()
