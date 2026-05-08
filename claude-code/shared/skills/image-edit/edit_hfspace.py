#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["gradio-client>=1.4"]
# ///
"""Image edit via HuggingFace Space (Qwen-Image-Edit-2511-Fast).

Free, no auth, no API key. Uses public Gradio Space — rate-limited but
no quota. Quality is close to FLUX.1 Kontext for background replace and
relight on plant/pot/interior shots.

Falls back across multiple Spaces because any single one can be
sleeping or queued.
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

from gradio_client import Client, handle_file


# Order matters: 4-step (fastest), 8-step, full-quality.
SPACE_CANDIDATES = [
    "linoyts/Qwen-Image-Edit-2511-Fast",
    "multimodalart/Qwen-Image-Edit-Fast",
    "Qwen/Qwen-Image-Edit-2511",
    "Qwen/Qwen-Image-Edit",
]


def edit(input_path: Path, prompt: str, output_path: Path) -> None:
    last_err: Exception | None = None
    img = handle_file(str(input_path))

    for space in SPACE_CANDIDATES:
        try:
            client = Client(space)
        except Exception as exc:
            last_err = exc
            print(f"[skip] {space}: connect failed: {exc}", file=sys.stderr)
            continue

        for call_kwargs in _build_call_attempts(img, prompt):
            try:
                result = client.predict(**call_kwargs)
            except Exception as exc:
                last_err = exc
                print(f"[skip] {space} {call_kwargs.get('api_name')}: {exc}", file=sys.stderr)
                continue
            path = _extract_path(result)
            if not path:
                last_err = RuntimeError(f"unexpected result shape: {result!r}")
                continue
            output_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, output_path)
            print(f"OK: {output_path} (space={space}, api={call_kwargs.get('api_name')})")
            return

    raise SystemExit(f"all Spaces failed. last error: {last_err}")


def _build_call_attempts(img, prompt: str):
    """Yield kwargs combos to try — Spaces have inconsistent param names."""
    common = [
        {"image": img, "prompt": prompt},
        {"input_image": img, "prompt": prompt},
        {"image": img, "edit_prompt": prompt},
        {"image": img, "instruction": prompt},
    ]
    for params in common:
        for api_name in ("/predict", "/infer", "/edit", "/generate"):
            yield {**params, "api_name": api_name}
        yield params  # let gradio pick the default endpoint


def _extract_path(result):
    if isinstance(result, str):
        return result
    if isinstance(result, (list, tuple)):
        for item in result:
            path = _extract_path(item)
            if path:
                return path
    if isinstance(result, dict):
        for key in ("path", "image", "url", "value"):
            if key in result:
                path = _extract_path(result[key])
                if path:
                    return path
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")
    edit(args.input, args.prompt, args.output)


if __name__ == "__main__":
    main()
