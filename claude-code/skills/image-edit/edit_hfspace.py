#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["gradio-client>=1.4", "Pillow>=10"]
# ///
"""Image edit via HuggingFace Space (Qwen-Image-Edit-2511 family).

Free, no auth, no API key. Single-input edit OR multi-reference compose
(up to ~3 images) — Qwen-Image-Edit-2511 takes a list of images natively.

Falls back across Spaces because any single one can be sleeping / queued
/ in RUNTIME_ERROR state.
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

from gradio_client import Client, handle_file
from PIL import Image


# Order: fastest first, then full-quality, then official.
SPACES = [
    "linoyts/Qwen-Image-Edit-2511-Fast",
    "Qwen/Qwen-Image-Edit-2511",
    "multimodalart/Qwen-Image-Edit-Fast",
]


def edit(input_path: Path, ref_paths: list[Path], prompt: str, output_path: Path) -> None:
    image_paths = [input_path] + list(ref_paths)
    width, height = _dims(input_path)
    images_arg = [{"image": handle_file(str(p)), "caption": None} for p in image_paths]

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
                images=images_arg,
                prompt=prompt,
                seed=0,
                randomize_seed=True,
                true_guidance_scale=4.0,
                num_inference_steps=8 if "Fast" in space else 20,
                height=height,
                width=width,
                rewrite_prompt=True,
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
        print(f"OK: {output_path} (space={space}, refs={len(ref_paths)})")
        return

    raise SystemExit(f"all Spaces failed. last error: {last_err}")


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
    parser.add_argument(
        "--ref",
        type=Path,
        action="append",
        default=[],
        help="extra reference image; pass --ref multiple times for up to ~3 total",
    )
    args = parser.parse_args()
    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")
    for r in args.ref:
        if not r.exists():
            sys.exit(f"ref not found: {r}")
    edit(args.input, args.ref, args.prompt, args.output)


if __name__ == "__main__":
    main()
