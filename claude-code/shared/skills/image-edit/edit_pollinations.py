#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["requests>=2.31"]
# ///
"""Image edit via Pollinations Kontext. Requires free API key.

As of 2026 the Kontext model is gated behind enter.pollinations.ai. The
public endpoint refuses requests with: "kontext model is only available
on enter.pollinations.ai". Get a free key at https://auth.pollinations.ai
and set POLLINATIONS_API_KEY.

Pipeline: upload input to catbox.moe (anonymous, no auth) → call Kontext
on image.pollinations.ai with the public URL + API key.
"""
from __future__ import annotations

import argparse
import os
import sys
import urllib.parse
from pathlib import Path

import requests


CATBOX_URL = "https://catbox.moe/user/api.php"
KONTEXT_BASE = "https://image.pollinations.ai/prompt/"


def upload_catbox(input_path: Path) -> str:
    with open(input_path, "rb") as fh:
        resp = requests.post(
            CATBOX_URL,
            data={"reqtype": "fileupload"},
            files={"fileToUpload": fh},
            headers={"User-Agent": "image-edit-skill/1.0"},
            timeout=60,
        )
    resp.raise_for_status()
    url = resp.text.strip()
    if not url.startswith("http"):
        sys.exit(f"catbox upload failed: {url!r}")
    return url


def kontext(prompt: str, image_url: str, api_key: str, output_path: Path,
            width: int, height: int, seed: int | None) -> None:
    params = {
        "model": "kontext",
        "image": image_url,
        "width": str(width),
        "height": str(height),
        "nologo": "true",
        "token": api_key,
    }
    if seed is not None:
        params["seed"] = str(seed)
    url = KONTEXT_BASE + urllib.parse.quote(prompt, safe="") + "?" + urllib.parse.urlencode(params)
    resp = requests.get(
        url,
        timeout=300,
        headers={
            "User-Agent": "image-edit-skill/1.0",
            "Authorization": f"Bearer {api_key}",
        },
    )
    if resp.status_code != 200 or not resp.headers.get("content-type", "").startswith("image/"):
        sys.exit(f"kontext failed: {resp.status_code} {resp.text[:500]}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(resp.content)
    print(f"OK: {output_path} ({len(resp.content)} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--width", type=int, default=1024)
    parser.add_argument("--height", type=int, default=1024)
    parser.add_argument("--seed", type=int, default=None)
    args = parser.parse_args()

    api_key = os.environ.get("POLLINATIONS_API_KEY")
    if not api_key:
        sys.exit(
            "POLLINATIONS_API_KEY not set. Get a free key at "
            "https://auth.pollinations.ai then export POLLINATIONS_API_KEY=..."
        )

    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")

    image_url = upload_catbox(args.input)
    print(f"uploaded: {image_url}")
    kontext(args.prompt, image_url, api_key, args.output, args.width, args.height, args.seed)


if __name__ == "__main__":
    main()
