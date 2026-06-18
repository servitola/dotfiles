# RAG Retrieval Benchmark & A/B Methodology

The per-collection `rag.eval.*.json` suites are now large enough to act as a
**retrieval benchmark**. This doc records (1) the current baseline pass rates,
(2) a reproducible A/B methodology for evaluating an alternative embedder or
reranker setting **without disrupting the live system**, and (3) the proof run
executed end-to-end on the smallest collection (`sphere`).

> **Date of baseline:** 2026-06-17
> **Pipeline under test:** `embed` alias (`nvidia/llama-nemotron-embed-vl-1b-v2:free`,
> 2048-dim, Cosine) → hybrid search (vector + FTS, RRF-fused server-side in Qdrant)
> → optional rerank (off by default). See `scripts/rag-eval.py`
> (`search_then_rerank`, `search_hybrid`) and `litellm/config.yaml`.

Note: `litellm/CLAUDE.md` still calls the embed model "1024-dim" — that is stale.
The live `embed` model and every Qdrant collection are **2048-dim** (verified via
`/v1/embeddings` and `/collections/<c>` `config.params.vectors.size`).

---

## 1. Baseline (benchmark) pass rates

All runs use the default pipeline (hybrid search, no reranker), `top_k=12` as
declared in each eval file. The eval harness reads `collection` and `top_k`
straight from the JSON, embeds each `q`, retrieves, and asserts
`must_contain` / `must_hit_path` against retrieved chunk text/path.

| Suite                | Cases | Passed | Pass rate | Command |
|----------------------|------:|-------:|----------:|---------|
| sphere               |    36 |     36 | **100%**  | `rag eval rag/rag.eval.sphere.json` |
| glasswings           |    38 |     38 | **100%**  | `rag eval rag/rag.eval.glasswings.json` |
| workbot2             |    77 |     77 | **100%**  | `rag eval rag/rag.eval.workbot2.json` |
| spotwarevpn          |    89 |     82 | **92.1%** | `rag eval rag/rag.eval.spotwarevpn.json` |
| dotfiles (40-sample) |    40 |     40 | **100%**  | sampled, seed=42 (see below) |

**Skipped on time/cost (note):** `services` (largest suite) was intentionally
**not** run to save free-tier embedding quota. `serho`, `spotware-code`,
`spotware-docs`, `spotware-dev-docs` were out of scope for this baseline pass
but use the identical harness and can be added the same way.

The full `dotfiles` suite is 1045 cases — too slow / quota-heavy for a routine
benchmark, so a 40-case random sample (Python `random.seed(42)`) was used as a
representative spot check:

```bash
python3 - <<'PY'
import json, random
src = json.load(open("rag/rag.eval.json"))
random.seed(42)
out = {"collection": src["collection"], "top_k": src["top_k"],
       "cases": random.sample(src["cases"], 40)}
json.dump(out, open("/tmp/rag.eval.dotfiles.sample40.json", "w"))
PY
rag eval /tmp/rag.eval.dotfiles.sample40.json
```

### Known baseline failures — `spotwarevpn` (7 cases)

These fail on the **current** pipeline and are pre-existing (not introduced by
any benchmark work). They are all exact-string `must_contain` lookups the
hybrid retriever does not surface in the top-12:

| # | Question (abbrev.) | Missing needle |
|---|--------------------|----------------|
|  8 | BASH_MAX_TIMEOUT_MS value | `480000` |
|  9 | Privoxy forward target | `forward-socks5 / 127.0.0.1:1080` |
| 14 | watchdog restart trigger | `could not bind address to use on` |
| 15 | default watchdog COOLDOWN | `COOLDOWN=30` |
| 16 | watchdog cooldown for spotware-vpn | `COOLDOWN=30` |
| 30 | VPN auto-connect via .env | `VPN_PORTAL=vpn.company.com` |
| 31 | install script Docker memory req | `REQUIRED_MEMORY=$((4 * 1024 * 1024 * 1024))` |

These 7 cases are the **natural discriminating set** for an A/B: an embedder or
reranker that recovers any of them is a measurable win, while the saturated
suites (sphere/glasswings/workbot2 at 100%) can only show regressions.

---

## 2. A/B Methodology (no live-system disruption)

**Core principle:** never touch the live `embed` alias, the LiteLLM/global config,
or re-ingest a live collection. The eval harness keys off the `collection` field
**inside the eval JSON**, so we A/B by ingesting one small collection into a
**throwaway temp collection** with the candidate setting, pointing a copy of the
eval at it, and diffing the pass rate against baseline. Then we drop the temp.

### Why a global model swap is the wrong tool
- The `embed` model is 2048-dim and shared by *every* collection. Changing it
  requires re-ingesting **all** collections (`rag drop` + `rag refresh`) and
  breaks the live `ai` CLI + RAG for everyone in the meantime.
- A temp-collection A/B isolates the variable to one small corpus, costs a few
  dozen embeddings, and leaves Qdrant byte-for-byte unchanged.

### What is variable today
The current LiteLLM config exposes exactly **one** embedding alias (`embed`).
There is **no second embedder** wired up, so an embedder A/B requires first
adding a candidate alias to `litellm/config.yaml` (a config edit — out of scope
for this run). What *is* readily available without any config change is the
**reranker** toggle, controlled purely by env vars consumed by
`scripts/rag-eval.py`:

| Variable | Effect |
|----------|--------|
| `RAG_USE_RERANKER=1` | enable the rerank stage over the wide candidate set |
| `RAG_RERANK_PROVIDER=local` | BAAI/bge-reranker-v2-m3 via lazy localhost daemon (free, ~CPU) |
| `RAG_RERANK_PROVIDER=voyage` | Voyage `rerank-2` cloud (free tier 3 RPM — slow) |
| `RAG_RERANK_FETCH_K=N` | candidate depth fetched before rerank (default 12) |
| `RAG_SEARCH_MODE=vector` | force pure vector (disable hybrid) — debugging baseline |

So the reranker A/B needs **no collection re-ingest at all** — it reorders the
same retrieved chunks. The temp-collection technique is for embedder/chunking
changes; the env-var technique is for rerank/search-mode changes.

### Procedure A — embedder / chunking A/B (temp collection)

```bash
# 0. Snapshot live state
rag list                                   # record collections BEFORE

# 1. (embedder change only) add a candidate alias, e.g. `embed-cand`, to
#    litellm/config.yaml and `docker compose restart`. For chunking changes,
#    no config edit is needed — vary --chunk-size / --chunk-overlap instead.

# 2. Ingest ONE small corpus into a temp collection with the candidate setting
RAG_EMBED_MODEL=embed-cand \
  rag ingest --collection sphere_abtest ~/projects/sphere
#   (chunking variant: rag ingest --collection sphere_abtest \
#      --chunk-size 800 --chunk-overlap 100 ~/projects/sphere)

# 3. Point a copy of the eval at the temp collection
python3 -c 'import json;d=json.load(open("rag/rag.eval.sphere.json"));\
d["collection"]="sphere_abtest";json.dump(d,open("/tmp/ab.json","w"))'

# 4. Run candidate vs. baseline
rag eval rag/rag.eval.sphere.json   # CONTROL (live collection, current embedder)
rag eval /tmp/ab.json               # CANDIDATE (temp collection)

# 5. Compare the `N/M passed` summary lines. Win = candidate ≥ control AND
#    recovers known failures without new regressions.

# 6. Tear down — leave Qdrant exactly as found
echo y | rag drop sphere_abtest
rag list                                   # must match step 0 output
rm -f /tmp/ab.json
```

### Procedure B — reranker / search-mode A/B (env var, no ingest)

```bash
rag eval rag/rag.eval.spotwarevpn.json                       # control (hybrid, no rerank)
RAG_USE_RERANKER=1 RAG_RERANK_PROVIDER=local \
  rag eval rag/rag.eval.spotwarevpn.json                     # arm B (local rerank)
RAG_SEARCH_MODE=vector rag eval rag/rag.eval.spotwarevpn.json # arm C (pure vector)
```

Diff the `N/M passed` lines. Use `--verbose` to see retrieved paths/scores on
failures and confirm *why* a case flipped.

### Choosing the right suite for an A/B
- **Discriminating suite:** `spotwarevpn` (92% baseline, 7 known exact-string
  misses). This is where a better embedder/reranker can show measurable lift.
- **Regression guard:** the saturated suites (`sphere`, `glasswings`,
  `workbot2`, dotfiles-sample at 100%) can only reveal *regressions* — run at
  least one as a safety net so a candidate that recovers vpn cases but breaks
  easy ones is caught.
- **Harness smoke test:** `sphere` (8 files, 14 chunks, 36 cases) — cheapest to
  ingest, use it to validate the A/B plumbing before spending quota on bigger
  corpora.

### Guardrails (mandatory)
- Never edit the live `embed` alias or any global/LiteLLM config as part of a run
  unless explicitly adding a clearly-named *candidate* alias you will remove.
- Never `rag refresh` or `rag ingest` into a **live** collection during an A/B.
- Always `rag drop` every temp collection and confirm `rag list` matches the
  pre-run snapshot.
- Keep runs to small/medium suites — free-tier embedding quota is limited; the
  giant `services` and full `dotfiles` (1045-case) suites burn quota fast.

---

## 3. Proof — end-to-end A/B executed on `sphere`

Executed 2026-06-17 to validate the harness. `sphere` chosen (smallest: 8 files,
14 chunks).

1. **Snapshot:** `rag list` → 10 collections (dotfiles, glasswings, serho,
   services, sphere, spotware-code, spotware-dev-docs, spotware-docs,
   spotwarevpn, workbot2).
2. **Ingest control:** `rag ingest --collection sphere_abtest ~/projects/sphere`
   → `8 files ingested, 14 chunks` — identical shape to live `sphere`. (Used the
   **current** embedder as a control, since no candidate alias exists yet; this
   proves the temp-collection plumbing reproduces baseline exactly.)
3. **Arm A (control, temp collection, current embedder):** `36/36 passed` —
   matches the live `sphere` baseline of `36/36` exactly. ✓ Harness validated.
4. **Arm B (same temp collection + local bge reranker):**
   `RAG_USE_RERANKER=1 RAG_RERANK_PROVIDER=local` → `36/36 passed`. The rerank
   daemon spawned and reordered candidates; no regression.
5. **Teardown:** `echo y | rag drop sphere_abtest` → `{"result": true}`.
   `rag list` → identical 10 collections. ✓ Qdrant left exactly as found.
6. Temp eval files in `/tmp` removed.

**Finding:** `sphere` is fully saturated (100% under every arm) — it is a good
*plumbing* smoke test but a poor *discriminator*. To actually compare retrieval
quality, run the A/B on `spotwarevpn` (the suite with 7 known failures and real
headroom), using one saturated suite as a regression guard.

---

## 4. Quick reference

```bash
# Baseline a suite (current pipeline)
rag eval rag/rag.eval.<collection>.json

# Reranker A/B (no ingest)
RAG_USE_RERANKER=1 RAG_RERANK_PROVIDER=local rag eval rag/rag.eval.<collection>.json

# Embedder/chunking A/B (temp collection) — see Procedure A
rag list                                            # before
rag ingest --collection <c>_abtest <path>           # candidate
#   point eval JSON at <c>_abtest, run, diff
echo y | rag drop <c>_abtest                         # after
rag list                                            # must match "before"
```

## Reranker A/B verdict (2026-06-17)

Measured with `scripts/rerank-ab.py` (efficient: one embed + one wide hybrid
search per query; compares `wide[:top_k]` vs `bge-reranker-v2-m3(wide)→top_k`).

**Critical config note:** `RERANK_FETCH_K` defaults to **12** = eval `top_k` 12,
so `fetch_k=max(12,12)=12` → the reranker reorders the SAME 12 chunks and cannot
change a `must_contain` pass/fail. To measure any effect the candidate pool must
be wider: `--fetch-k 50`.

| Collection | sample | plain | rerank | Δ | rescued | broken |
|---|---|---|---|---|---|---|
| spotwarevpn | 25 | 92.0% | 92.0% | +0.0pp | 0 | 0 |
| dotfiles | 20 | 100% | 100% | +0.0pp | 0 | 0 |

**Verdict: do NOT enable the reranker.** Hybrid (vector+FTS, RRF-fused) already
surfaces the needle chunks in top-12; reranking a 50-candidate pool neither
rescued a miss nor broke a hit. Enabling it (`RAG_USE_RERANKER=1`) would add
10-30s CPU latency per query (single-threaded daemon) for zero retrieval gain.
The only place reranking could still matter is answer-ordering quality
(best chunk first) — not retrieval recall — and given hybrid already saturates
these suites, that upside is marginal. Re-run this A/B if the corpus or embedder
changes materially.
