#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["gradio-client>=1.4", "Pillow>=10"]
# ///
"""Inpaint a region via HuggingFace Space (FLUX.1-Fill-dev).

Use when only part of the image must change (e.g. "denser plant in the
top-left corner, keep everything else"). White pixels in the mask are
repainted. Pass either a paint mask PNG or a --bbox x,y,w,h that is
rasterised into a rectangular mask.

Free, no auth. The Space uses Gradio's ImageEditor input — we wrap the
input + mask into the {background, layers, composite, id} dict.
"""
from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
from pathlib import Path

from gradio_client import Client, handle_file
from PIL import Image, ImageDraw


SPACES = [
    "black-forest-labs/FLUX.1-Fill-dev",
]


def inpaint(input_path: Path, mask_path: Path, prompt: str, output_path: Path) -> None:
    width, height = _dims(input_path)
    edit_images = {
        "background": handle_file(str(input_path)),
        "layers": [handle_file(str(mask_path))],
        "composite": handle_file(str(input_path)),
        "id": None,
    }

    last_err: Exception | None = None
    for space in SPACES:
        try:
            client = Client(space)
        except Exception as exc:
            last_err = exc
            print(f"[skip] {space}: connect failed: {exc}", file=sys.stderr)
            continue

        try:
            result = client.predict(
                edit_images=edit_images,
                prompt=prompt,
                seed=0,
                randomize_seed=True,
                width=width,
                height=height,
                guidance_scale=30.0,
                num_inference_steps=28,
                api_name="/infer",
            )
        except Exception as exc:
            last_err = exc
            print(f"[skip] {space}: predict failed: {exc}", file=sys.stderr)
            continue

        path = _extract_path(result)
        if not path:
            last_err = RuntimeError(f"unexpected result shape from {space}: {result!r}")
            print(f"[skip] {space}: {last_err}", file=sys.stderr)
            continue

        output_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, output_path)
        print(f"OK: {output_path} (space={space})")
        return

    raise SystemExit(f"all inpaint Spaces failed. last error: {last_err}")


def _bbox_to_mask(input_path: Path, bbox_str: str) -> Path:
    try:
        x, y, w, h = (int(v.strip()) for v in bbox_str.split(","))
    except ValueError:
        sys.exit(f"--bbox must be x,y,w,h integers, got: {bbox_str!r}")
    with Image.open(input_path) as src:
        size = src.size
    mask = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(mask).rectangle([x, y, x + w, y + h], fill=(255, 255, 255, 255))
    fd, out = tempfile.mkstemp(prefix="inpaint_mask_", suffix=".png")
    mask.save(out)
    Path(out).chmod(0o644)
    return Path(out)


def _dims(path: Path) -> tuple[int, int]:
    with Image.open(path) as im:
        return im.size


def _extract_path(result):
    if isinstance(result, str):
        return result
    if isinstance(result, (list, tuple)):
        for item in result:
            p = _extract_path(item)
            if p:
                return p
    if isinstance(result, dict):
        for k in ("path", "image", "url", "value"):
            if k in result:
                p = _extract_path(result[k])
                if p:
                    return p
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    mask_group = parser.add_mutually_exclusive_group(required=True)
    mask_group.add_argument("--mask", type=Path, help="PNG mask, white=repaint, same size as input")
    mask_group.add_argument("--bbox", help="rectangle to repaint, format: x,y,w,h in input pixels")
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")

    if args.mask:
        if not args.mask.exists():
            sys.exit(f"mask not found: {args.mask}")
        mask_path = args.mask
    else:
        mask_path = _bbox_to_mask(args.input, args.bbox)

    inpaint(args.input, mask_path, args.prompt, args.output)


if __name__ == "__main__":
    main()
