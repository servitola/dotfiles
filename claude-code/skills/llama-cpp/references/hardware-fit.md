# Hardware Fit — what actually runs on this machine (offline)

The Hub workflows in `SKILL.md` tell you which quants *exist*. This file answers the
other half **without any network**: given the machine's RAM/VRAM, which model + quant +
context window actually fit, and how to rank the survivors.

The math is ported from Osmantic ODS `scripts/select-model.py` (`usable_memory_gb`,
`selector_required_memory_gb`, `rank_models`, `score_model`). Use the companion script
`scripts/fit.py` to run it; the formulas below explain what it computes.

## 1. Usable memory (capacity)

Never assume all RAM/VRAM is available to the model — the OS, other apps, and the KV
cache all take a share. Capacity by backend:

| Backend | Usable memory (GB) | Why the haircut |
|---|---|---|
| **Apple Silicon / any unified memory** | `max(ram_gb * 0.55, 2.0)` | RAM is shared by macOS, apps, weights **and** KV cache; ~55% is the safe slice llama.cpp can claim without paging |
| **Discrete GPU** (NVIDIA/AMD/Intel Arc) | `vram_mb / 1024` | weights + KV must live in VRAM; system RAM doesn't help once you offload all layers |
| **CPU only** | `min(max(ram_gb * 0.35, 3.0), 8.0)` | pure-CPU inference is RAM-bandwidth bound; keep a hard ceiling so you pick a small, responsive model |

The 0.55 unified-memory rule is the single most useful number here: on a 64 GB M-series
Mac you plan against **~35 GB**, not 64.

## 2. Required memory for a candidate

```
required_gb = max(vram_required_gb, weights_gb + kv_cache_gb)
```

- **`weights_gb`** — GGUF size on disk. Estimate from params × quant (GB per billion
  params, derived from `quantization.md`):

  | Quant | GB / 1B params |
  |---|---|
  | Q2_K | 0.39 |
  | Q3_K_M | 0.47 |
  | Q4_K_S | 0.56 |
  | **Q4_K_M** | **0.59** |
  | Q5_K_M | 0.69 |
  | Q6_K | 0.79 |
  | Q8_0 | 1.00 |
  | F16 | 1.86 |

  e.g. a 30B model at Q4_K_M ≈ `30 × 0.59 ≈ 17.7 GB`.

- **`kv_cache_gb`** — grows with context length. Rough f16-KV estimate (GQA assumed):
  `kv_cache_gb ≈ context_k × kv_per_1k`, with `kv_per_1k` by model size:

  | Params | `kv_per_1k` (GB per 1K tokens, f16) |
  |---|---|
  | ≤ 4B | 0.05 |
  | ≤ 9B | 0.13 |
  | ≤ 16B | 0.22 |
  | ≤ 40B | 0.45 |
  | > 40B | 0.80 |

  e.g. 30B at 32K ≈ `32 × 0.45 ≈ 14 GB`. This is deliberately conservative and
  **overestimates for MoE / non-GQA edge cases** — override with a measured value
  (`--kv-gb-per-1k`) when you know the architecture, or check `llama-server` startup
  logs (`KV self size = …`). Quantized KV (`--cache-type-k q8_0`) roughly halves it.

## 3. Fit check

A candidate fits when:

```
required_gb ≤ capacity_gb + 0.25
```

The `0.25 GB` tolerance mirrors ODS — it absorbs rounding without letting a model that
clearly overflows sneak through.

## 4. Ranking the survivors

Among models that fit, prefer the one that best matches the job — not just the biggest.
Score (higher = better), from ODS `score_model`:

- **specialty match** — `code = 4.4`, `general/chat = 3.8`, others in between (weight the
  task the user actually asked for)
- **context bonus** — more usable context scores higher (log-scaled, so 32K→128K matters
  less than 4K→32K)
- **capability bonus** — larger param count within the same fit
- **headroom penalty** — subtract when `required_gb` sits right at `capacity_gb`; a model
  that leaves no slack will page/OOM under real prompts

Pick the top score, not the largest model. On a 64 GB Mac a 30B Q4_K_M at 32K that leaves
~17 GB headroom beats a 70B Q3_K_M at 8K that's one long prompt away from swapping.

## 5. Run it

```bash
# capacity + "what fits" guide for this machine
scripts/fit.py --backend apple --ram-gb 64

# rank explicit candidates (JSON list of {name,params_b,quant,context_k,specialty})
scripts/fit.py --backend apple --ram-gb 64 --models candidates.json

# discrete GPU
scripts/fit.py --backend nvidia --vram-mb 24576 --models candidates.json
```

`fit.py` is stdlib-only (no network, no deps). Feed it the sizes you already pulled from
the HF tree API (`SKILL.md` step 5) as `--models`, or let it estimate from params.
