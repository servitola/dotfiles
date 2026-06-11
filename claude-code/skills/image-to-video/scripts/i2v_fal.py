#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fal-client>=0.4"]
# ///
"""Image-to-video via fal.ai. Animates one still image into a short clip.

Default model: Kling 2.1 Standard (good motion + identity preservation).
Swap with --model to use Pro / Hailuo / Wan / LTX — see references/models.md.

  i2v_fal.py --input cat.png --prompt "the cat slurps noodles" --output out.mp4

Requires FAL_KEY in env or in ~/.config/openai_key.sh.
"""
from __future__ import annotations
import argparse, os, re, sys, urllib.request
from pathlib import Path
import fal_client

DEFAULT_MODEL = "fal-ai/kling-video/v2.1/standard/image-to-video"
DEFAULT_NEGATIVE = "blur, distort, low quality, morphing, flicker, extra limbs, deformed face"


def _load_key() -> None:
    if os.environ.get("FAL_KEY"):
        return
    p = Path.home() / ".config" / "openai_key.sh"
    if p.exists():
        pat = re.compile(r'^\s*(?:export\s+)?FAL_KEY\s*=\s*["\']?([^"\'#\s]+)')
        for line in p.read_text().splitlines():
            m = pat.match(line)
            if m:
                os.environ["FAL_KEY"] = m.group(1)
                return
    sys.exit("FAL_KEY not set and not found in ~/.config/openai_key.sh")


def _check_balance() -> float | None:
    """Return the fal.ai account balance in USD, or None if it can't be read.

    Used to tell a real "out of money" 403 apart from a "this model endpoint
    is unavailable" 403 — fal uses the same misleading message for both.
    """
    key = os.environ.get("FAL_KEY")
    if not key:
        return None
    req = urllib.request.Request(
        "https://rest.alpha.fal.ai/billing/user_balance",
        headers={"Authorization": f"Key {key}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return float(r.read().decode().strip())
    except Exception:
        return None


def run(args) -> None:
    _load_key()
    image_url = fal_client.upload_file(str(args.input))
    payload = {
        "prompt": args.prompt,
        "image_url": image_url,
        "duration": str(args.duration),
        "negative_prompt": args.negative,
    }
    if args.aspect:
        payload["aspect_ratio"] = args.aspect
    if args.cfg is not None:
        payload["cfg_scale"] = args.cfg

    try:
        res = fal_client.subscribe(args.model, with_logs=True, arguments=payload)
    except fal_client.client.FalClientHTTPError as e:
        status = getattr(e, "status_code", None)
        body = str(e)
        # fal returns 403 with a misleading "Exhausted balance" body when the
        # MODEL ENDPOINT itself is unavailable/deprecated — not an account issue.
        # Don't trust the message: verify the real balance, then say which it is.
        if status == 403:
            bal = _check_balance()
            if bal is None:
                sys.exit(f"MODEL_UNAVAILABLE: 403 on '{args.model}'. Could not verify "
                         f"balance — most likely this model endpoint is deprecated/renamed. "
                         f"Retry with the default Kling model (drop --model) or pick a current "
                         f"id from references/models.md. Raw: {body}")
            if bal > 0.05:
                sys.exit(f"MODEL_UNAVAILABLE: 403 on '{args.model}' but account balance is "
                         f"${bal:.2f} (NOT exhausted — fal's error text is misleading). "
                         f"This model endpoint is unavailable; retry with the default Kling "
                         f"model (drop --model) or another id from references/models.md.")
            sys.exit(f"BALANCE_EXHAUSTED: account balance is ${bal:.2f}. Top up at fal.ai.")
        raise
    video = res.get("video") if isinstance(res, dict) else None
    vurl = video.get("url") if isinstance(video, dict) else None
    if not vurl:
        sys.exit(f"unexpected fal response: {res!r}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(vurl) as r:
        args.output.write_bytes(r.read())
    print(f"OK: {args.output} (model={args.model})")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True, type=Path)
    ap.add_argument("--prompt", required=True, help="describe the MOTION, not the scene")
    ap.add_argument("--output", required=True, type=Path)
    ap.add_argument("--duration", default=5, type=int, help="seconds (model-dependent: often 5 or 10)")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--aspect", default=None, help="e.g. 1:1, 16:9, 9:16 (omit to keep source)")
    ap.add_argument("--negative", default=DEFAULT_NEGATIVE)
    ap.add_argument("--cfg", default=None, type=float, help="prompt adherence, 0.1-1.0 (Kling)")
    a = ap.parse_args()
    if not a.input.exists():
        sys.exit(f"input not found: {a.input}")
    run(a)


if __name__ == "__main__":
    main()
