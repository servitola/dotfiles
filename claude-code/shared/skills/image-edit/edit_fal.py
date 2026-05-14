#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fal-client>=0.4"]
# ///
"""Image edit via fal.ai FLUX Kontext Pro. Paid (~$0.04 per image).

Single-input edit OR multi-reference compose (up to 4 input images).
Kontext Pro = full-quality FLUX edit model, far above what the free HF
Space gives. Fast (3-6 sec end-to-end, no queue).

Requires FAL_KEY in env or in ~/.config/openai_key.sh. Costs land on
the fal.ai dashboard balance.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import urllib.request
from pathlib import Path

import fal_client


def edit(input_path: Path, ref_paths: list[Path], prompt: str, output_path: Path) -> None:
    _load_fal_key()

    input_url = fal_client.upload_file(str(input_path))
    if ref_paths:
        ref_urls = [fal_client.upload_file(str(p)) for p in ref_paths]
        endpoint = "fal-ai/flux-pro/kontext/multi"
        arguments = {
            "prompt": prompt,
            "image_urls": [input_url] + ref_urls,
        }
    else:
        endpoint = "fal-ai/flux-pro/kontext"
        arguments = {
            "prompt": prompt,
            "image_url": input_url,
        }

    result = fal_client.subscribe(endpoint, arguments=arguments, with_logs=False)
    image_url = _first_image_url(result)
    if not image_url:
        raise SystemExit(f"unexpected fal response: {result!r}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(image_url) as resp:
        output_path.write_bytes(resp.read())
    print(f"OK: {output_path} (endpoint={endpoint}, refs={len(ref_paths)}, cost≈$0.04)")


def _first_image_url(result):
    images = result.get("images") if isinstance(result, dict) else None
    if not images:
        return None
    first = images[0]
    return first.get("url") if isinstance(first, dict) else None


def _load_fal_key() -> None:
    if os.environ.get("FAL_KEY"):
        return
    secrets = Path.home() / ".config" / "openai_key.sh"
    if secrets.exists():
        pattern = re.compile(r'^\s*(?:export\s+)?FAL_KEY\s*=\s*["\']?([^"\'#\s]+)')
        for line in secrets.read_text().splitlines():
            m = pattern.match(line)
            if m:
                os.environ["FAL_KEY"] = m.group(1)
                return
    sys.exit("FAL_KEY not set and not found in ~/.config/openai_key.sh")


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
        help="extra reference image; pass --ref multiple times for up to 4 total inputs",
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
