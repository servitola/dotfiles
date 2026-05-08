#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["mflux>=0.17.5"]
# ///
"""Image edit via FLUX.1 Kontext [dev] running locally on Apple Silicon (MLX).

Best quality + zero quota. No recurring cost. After one-time setup runs
fully offline. ~12 GB disk for 4-bit quantized weights, ~6-15 sec per
1024 px image on M3-M4-M5.

One-time setup (do once on this machine):

    huggingface-cli login   # or: export HF_TOKEN=...
    # Visit https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev
    # and accept the model license while logged in.

    # Optional but strongly recommended — pre-quantize and save the model
    # so the per-run peak RAM drops from ~27 GB to ~7 GB:
    uv run --with "mflux>=0.17.5" mflux-save \\
        --model dev-kontext --quantize 4 \\
        --path ~/projects/ai-models-collection/flux1-kontext-dev-q4

Then this script will pick the saved quantized model automatically when
DEFAULT_MODEL_PATH exists, or download from HF on first run.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import mlx.core as mx

try:
    from mflux import Flux1Kontext  # type: ignore
except ImportError:
    from mflux.models.flux.variants.kontext.flux_kontext import Flux1Kontext


DEFAULT_MODEL_PATH = Path("~/projects/ai-models-collection/flux1-kontext-dev-q4").expanduser()


def edit(
    input_path: Path,
    prompt: str,
    output_path: Path,
    *,
    quantize: int,
    steps: int,
    seed: int,
    guidance: float,
    width: int,
    height: int,
    model_path: Path | None,
    low_ram: bool,
    image_strength: float | None,
) -> None:
    if low_ram:
        # Mirrors what `mflux-generate-kontext --low-ram` does internally:
        # disable MLX intermediate-tensor caches so peak RAM stays ~equal
        # to the active model weights instead of spiking with activations.
        mx.set_cache_limit(0)
        mx.set_wired_limit(0)
    if model_path is not None:
        # Pre-quantized weights on disk — load directly, no bf16 intermediate.
        flux = Flux1Kontext(model_path=str(model_path))
    else:
        flux = Flux1Kontext(quantize=quantize)
    image = flux.generate_image(
        seed=seed,
        prompt=prompt,
        num_inference_steps=steps,
        guidance=guidance,
        width=width,
        height=height,
        image_path=str(input_path),
        image_strength=image_strength,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path=str(output_path), export_json_metadata=False)
    print(f"OK: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--quantize", type=int, default=4, choices=[3, 4, 5, 6, 8])
    parser.add_argument("--steps", type=int, default=20)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--guidance", type=float, default=2.5)
    parser.add_argument("--width", type=int, default=1024)
    parser.add_argument("--height", type=int, default=1024)
    parser.add_argument(
        "--model-path",
        type=Path,
        default=None,
        help=(
            "Path to a pre-quantized model dir saved via `mflux-save`. "
            f"Defaults to {DEFAULT_MODEL_PATH} if it exists, else falls "
            "back to fresh quantization (higher peak RAM)."
        ),
    )
    parser.add_argument(
        "--no-low-ram",
        action="store_true",
        help="Disable MLX low-RAM mode (faster but higher peak memory).",
    )
    parser.add_argument(
        "--image-strength",
        type=float,
        default=None,
        help=(
            "How much noise to inject into the input before denoising — "
            "same semantics as SD img2img strength. LOWER (0.1-0.4) = "
            "less noise = more input preserved (subject stays close to "
            "original). HIGHER (0.6-0.9) = more noise = more freedom to "
            "repaint (better integration into a new scene). Default None "
            "lets Kontext decide and is right for most edits. Important: "
            "effective_denoise_steps ≈ steps × (1 - strength). When you "
            "raise strength, raise --steps too so denoising completes — "
            "high strength + few steps yields noisy output. Aim for at "
            "least 6 effective steps. Not a magic 'concept change' knob: "
            "if the prompt asks for a totally different image, tune all "
            "you want, the result will still rely on the prompt."
        ),
    )
    args = parser.parse_args()
    if args.model_path is None and DEFAULT_MODEL_PATH.exists():
        args.model_path = DEFAULT_MODEL_PATH

    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")
    hf_token = (
        os.environ.get("HF_TOKEN")
        or os.environ.get("HUGGING_FACE_HUB_TOKEN")
        or os.environ.get("HUGGINGFACE_READ_API_KEY")
    )
    if hf_token and not os.environ.get("HF_TOKEN"):
        os.environ["HF_TOKEN"] = hf_token
        os.environ.setdefault("HUGGING_FACE_HUB_TOKEN", hf_token)
    if not (hf_token or Path("~/.cache/huggingface/token").expanduser().exists()):
        sys.exit(
            "HF auth missing. Set HF_TOKEN (or HUGGINGFACE_READ_API_KEY), "
            "then accept license at "
            "https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev"
        )

    edit(
        args.input,
        args.prompt,
        args.output,
        quantize=args.quantize,
        steps=args.steps,
        seed=args.seed,
        guidance=args.guidance,
        width=args.width,
        height=args.height,
        model_path=args.model_path,
        low_ram=not args.no_low_ram,
        image_strength=args.image_strength,
    )


if __name__ == "__main__":
    main()
