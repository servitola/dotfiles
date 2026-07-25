#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Offline hardware-fit for local GGUF models.

Given a machine's RAM/VRAM, answer: which model + quant + context actually fit,
and rank the survivors. No network, no deps. Math ported from Osmantic ODS
`scripts/select-model.py` — see references/hardware-fit.md for the formulas.

Examples:
    fit.py --backend apple --ram-gb 64
    fit.py --backend apple --ram-gb 64 --models candidates.json --task code
    fit.py --backend nvidia --vram-mb 24576 --models -   # JSON on stdin
"""
from __future__ import annotations

import argparse
import json
import math
import sys

# GGUF size in GB per 1B params, by quant (derived from references/quantization.md).
QUANT_GB_PER_B = {
    "Q2_K": 0.39, "Q3_K_S": 0.44, "Q3_K_M": 0.47, "Q4_K_S": 0.56,
    "Q4_K_M": 0.59, "Q5_K_S": 0.65, "Q5_K_M": 0.69, "Q6_K": 0.79,
    "Q8_0": 1.00, "F16": 1.86,
}

# Specialty weight for ranking (ODS score_model).
SPECIALTY_WEIGHT = {"code": 4.4, "reasoning": 4.1, "general": 3.8, "chat": 3.8, "fast": 3.4}

TOLERANCE_GB = 0.25  # ODS fit tolerance


def kv_per_1k_gb(params_b: float) -> float:
    """Rough f16-KV cache, GB per 1K tokens (GQA assumed). Conservative."""
    if params_b <= 4:
        return 0.05
    if params_b <= 9:
        return 0.13
    if params_b <= 16:
        return 0.22
    if params_b <= 40:
        return 0.45
    return 0.80


def usable_memory_gb(backend: str, ram_gb: float, vram_mb: float, unified: bool) -> float:
    """Memory the model can actually claim (ODS usable_memory_gb)."""
    if backend == "apple" or unified:
        return max(ram_gb * 0.55, 2.0)
    if backend == "cpu":
        return min(max(ram_gb * 0.35, 3.0), 8.0)
    # discrete GPU
    return vram_mb / 1024.0


def weights_gb(params_b: float, quant: str) -> float:
    per_b = QUANT_GB_PER_B.get(quant)
    if per_b is None:
        raise SystemExit(f"unknown quant {quant!r}; known: {', '.join(QUANT_GB_PER_B)}")
    return params_b * per_b


def required_gb(params_b: float, quant: str, context_k: float,
                kv_override: float | None, vram_required: float = 0.0) -> tuple[float, float, float]:
    w = weights_gb(params_b, quant)
    kv = context_k * (kv_override if kv_override is not None else kv_per_1k_gb(params_b))
    return max(vram_required, w + kv), w, kv


def score_model(params_b: float, context_k: float, specialty: str,
                headroom_gb: float, task: str | None) -> float:
    spec = specialty.lower()
    # If the user named a task, reward candidates matching it.
    weight = SPECIALTY_WEIGHT.get(spec, 3.6)
    if task and task.lower() == spec:
        weight += 1.0
    context_bonus = math.log2(max(context_k, 1)) * 0.3
    capability_bonus = math.log2(max(params_b, 1)) * 0.5
    headroom_penalty = max(0.0, 3.0 - headroom_gb) * 0.4  # punish near-OOM picks
    return weight + context_bonus + capability_bonus - headroom_penalty


def rank(models: list[dict], capacity: float, kv_override: float | None, task: str | None) -> list[dict]:
    out = []
    for m in models:
        params_b = float(m["params_b"])
        quant = m.get("quant", "Q4_K_M")
        context_k = float(m.get("context_k", 8))
        specialty = m.get("specialty", "general")
        req, w, kv = required_gb(params_b, quant, context_k, kv_override,
                                 float(m.get("vram_required_gb", 0.0)))
        headroom = capacity - req
        fits = req <= capacity + TOLERANCE_GB
        out.append({
            "name": m.get("name", f"{params_b:g}B {quant}"),
            "params_b": params_b, "quant": quant, "context_k": context_k,
            "specialty": specialty, "weights_gb": round(w, 1), "kv_gb": round(kv, 1),
            "required_gb": round(req, 1), "headroom_gb": round(headroom, 1), "fits": fits,
            "score": round(score_model(params_b, context_k, specialty, headroom, task), 2) if fits else None,
        })
    # fitting first, by score desc; non-fitting last by smallest overflow
    out.sort(key=lambda r: (not r["fits"], -(r["score"] or -1e9), -r["headroom_gb"]))
    return out


def guide(capacity: float, kv_override: float | None) -> list[dict]:
    """What fits at Q4_K_M across common sizes and contexts."""
    rows = []
    for params_b in (3, 7, 8, 13, 14, 24, 30, 32, 70):
        row = {"params_b": params_b}
        for ctx in (8, 32, 128):
            req, _, _ = required_gb(params_b, "Q4_K_M", ctx, kv_override)
            row[f"{ctx}k"] = "fits" if req <= capacity + TOLERANCE_GB else "no"
        rows.append(row)
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description="Offline hardware-fit for local GGUF models.")
    ap.add_argument("--backend", required=True, choices=["apple", "nvidia", "amd", "intel", "cpu"])
    ap.add_argument("--ram-gb", type=float, default=0.0, help="total system RAM (GB)")
    ap.add_argument("--vram-mb", type=float, default=0.0, help="GPU VRAM (MB), for discrete backends")
    ap.add_argument("--unified", action="store_true", help="force unified-memory model (e.g. AMD Strix Halo)")
    ap.add_argument("--models", help="JSON file (or '-' for stdin) with a list of candidates")
    ap.add_argument("--task", help="bias ranking toward a specialty (code/general/chat/reasoning)")
    ap.add_argument("--kv-gb-per-1k", type=float, default=None, help="override KV estimate (GB per 1K tokens)")
    ap.add_argument("--json", action="store_true", help="emit JSON instead of a table")
    args = ap.parse_args()

    unified = args.unified or args.backend in ("apple", "amd")
    capacity = usable_memory_gb(args.backend, args.ram_gb, args.vram_mb, unified)

    if args.models:
        raw = sys.stdin.read() if args.models == "-" else open(args.models).read()
        candidates = json.loads(raw)
        ranked = rank(candidates, capacity, args.kv_gb_per_1k, args.task)
        if args.json:
            print(json.dumps({"capacity_gb": round(capacity, 1), "models": ranked}, indent=2))
            return
        print(f"Usable memory: {capacity:.1f} GB  ({args.backend})\n")
        print(f"{'model':<28} {'ctx':>5} {'weights':>8} {'kv':>6} {'need':>6} {'head':>6} {'fit':>4} {'score':>6}")
        for r in ranked:
            fit = "yes" if r["fits"] else "NO"
            score = "" if r["score"] is None else f"{r['score']:.2f}"
            print(f"{r['name']:<28} {r['context_k']:>4g}k {r['weights_gb']:>7.1f}G "
                  f"{r['kv_gb']:>5.1f}G {r['required_gb']:>5.1f}G {r['headroom_gb']:>5.1f}G "
                  f"{fit:>4} {score:>6}")
        return

    # No candidates: capacity + what-fits guide.
    rows = guide(capacity, args.kv_gb_per_1k)
    if args.json:
        print(json.dumps({"capacity_gb": round(capacity, 1), "guide_q4_k_m": rows}, indent=2))
        return
    print(f"Usable memory: {capacity:.1f} GB  ({args.backend}"
          f"{', unified' if unified else ''})\n")
    print("What fits at Q4_K_M (weights + f16 KV cache):")
    print(f"{'params':>7} {'@8k':>6} {'@32k':>6} {'@128k':>7}")
    for r in rows:
        print(f"{r['params_b']:>6}B {r['8k']:>6} {r['32k']:>6} {r['128k']:>7}")
    print("\nHeuristic only — confirm real KV in `llama-server` startup logs "
          "(KV self size). Feed exact HF sizes via --models to rank candidates.")


if __name__ == "__main__":
    main()
