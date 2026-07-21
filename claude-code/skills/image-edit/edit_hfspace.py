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
import os
import re
import shutil
import sys
from pathlib import Path

from gradio_client import Client, handle_file
from PIL import Image


# Order: fastest first, then full-quality, then the single-image Space.
# "multi" = takes a list of images (`images` arg); "single" = one `image`
# and no height/width, so it can only serve a no-ref edit.
SPACES = [
    ("linoyts/Qwen-Image-Edit-2511-Fast", "multi"),
    ("Qwen/Qwen-Image-Edit-2511", "multi"),
    ("multimodalart/Qwen-Image-Edit-Fast", "single"),
]


def edit(input_path: Path, ref_paths: list[Path], prompt: str, output_path: Path) -> None:
    image_paths = [input_path] + list(ref_paths)
    width, height = _dims(input_path)
    images_arg = [{"image": handle_file(str(p)), "caption": None} for p in image_paths]
    token = _hf_token()

    last_err: Exception | None = None
    for space, shape in SPACES:
        if shape == "single" and ref_paths:
            print(f"[skip] {space}: single-image Space, cannot take --ref", file=sys.stderr)
            continue
        try:
            client = Client(space, token=token)
        except Exception as exc:
            last_err = exc
            print(f"[skip] {space}: connect failed: {exc}", file=sys.stderr)
            continue

        common = {
            "prompt": prompt,
            "seed": 0,
            "randomize_seed": True,
            "true_guidance_scale": 4.0,
            "num_inference_steps": 8 if "Fast" in space else 20,
            "rewrite_prompt": True,
            "api_name": "/infer",
        }
        if shape == "multi":
            kwargs = {"images": images_arg, "height": height, "width": width, **common}
        else:
            kwargs = {"image": handle_file(str(input_path)), **common}

        try:
            result = client.predict(**kwargs)
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

    hint = ""
    if last_err and re.search(r"quota|GPU duration|GPU task aborted", str(last_err), re.I):
        hint = (" ZeroGPU quota/capacity is exhausted — this is not fixable by retrying"
                " soon; escalate to the paid engine (edit_fal.py).")
    raise SystemExit(f"all Spaces failed. last error: {last_err}.{hint}")


def _hf_token() -> str | None:
    """HF token from env or ~/.config/openai_key.sh — raises the ZeroGPU quota
    above the anonymous per-IP allowance."""
    for var in ("HF_TOKEN", "HUGGING_FACE_HUB_TOKEN"):
        if os.environ.get(var):
            return os.environ[var]
    secrets = Path.home() / ".config" / "openai_key.sh"
    if secrets.exists():
        pattern = re.compile(
            r'^\s*(?:export\s+)?(?:HF_TOKEN|HUGGING_FACE_HUB_TOKEN)\s*=\s*["\']?([^"\'#\s]+)'
        )
        for line in secrets.read_text().splitlines():
            m = pattern.match(line)
            if m:
                return m.group(1)
    return None


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
