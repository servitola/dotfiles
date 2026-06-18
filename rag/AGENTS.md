# rag — agent rules

## Eval corpus
- Eval files: `dotfiles` uses the canonical real file [rag.eval.json](rag.eval.json); every other collection uses `rag.eval.<collection>.json` (symlinks into `../../dotfiles_private/rag/` — private content stays off the public repo). Automation that writes eval cases MUST route `dotfiles` → `rag.eval.json`, never `rag.eval.dotfiles.json`.
- In any eval file, hand-written cases (`"manual": true`, or simply no `"auto"` flag) are read-only for automation. Only `"auto": true` cases are edited/retired by [scripts/rag-improve.py](scripts/rag-improve.py).
- A case `{q, must_contain|must_hit_path}` is valid only if the substring is actually retrievable. Verify new cases with [scripts/verify-case.py](scripts/verify-case.py) (same retrieval path as `rag eval`) before adding — don't hand-add unverified cases.

## Load-bearing internals — don't break
- Chunk header `File: <path>\nSummary: <line>\n\n` (built in [scripts/rag-ingest.py](scripts/rag-ingest.py)) is load-bearing. Touching it invalidates the index → `rag drop <collection> && rag refresh <collection>`.
- Scripts import `rag-eval.py` via `importlib` (hyphen filename). Don't rename its helpers — `embed() search() search_hybrid() search_then_rerank() run_case() check_assertion() http_json()` — importers (`rag-improve.py`, `verify-case.py`, `rerank-ab.py`, `answer-ab.py`) break silently.
- `rag improve` locks per collection: `/tmp/rag-improve.<collection>.lock`; `--all` rotates collections via cursor `/tmp/rag-improve.rotation.json`. Never spawn parallel runs of the SAME collection.
- Depends on `auto` + `embed` aliases in [../litellm/config.yaml](../litellm/config.yaml). Embed dim is 2048 — swapping it requires re-ingesting ALL collections.

## LiteLLM semantic cache — mandatory on chat calls
- Any chat call on an answer / eval / decompose path MUST send `"cache": {"no-cache": True}`. The cache matches by embedding similarity, so without it a novel question gets back a DIFFERENT prompt's cached completion (e.g. case-gen JSON, or an answer about the wrong topic). `rag-ask.py` and `rag-answer-eval.py` already do this — copy it into any new chat call.

## Retrieval / answer behaviour
- Reranker is OFF by default and stays off. A/B ([docs/retrieval-benchmark.md](docs/retrieval-benchmark.md)) showed hybrid (vector+FTS RRF) already saturates retrieval; rerank only reorders the same top-k unless `RAG_RERANK_FETCH_K` > eval `top_k`, and even wide it scored +0pp for 10–30 s/query cost. Re-run `scripts/rerank-ab.py` before reconsidering.
- `answer-eval` defaults: answer model `gpt` (what `rag ask` serves), judge `github-gpt4o-mini` (non-reasoning — clean verdicts, no `<think>` leak), top-10 chunks (matches `rag ask`). The old `fast/fast` default was an unreliable grader, not a real quality signal.
- `rag ask --decompose` splits a multi-hop question into sub-questions, retrieves per sub-question, answers over the union — opt-in (extra LLM call + N retrievals), for chained/complex questions where one query misses a hop.
- `append_gap` only logs a gap when the source file exists, is non-empty, and the `expect` substring literally occurs in it — keeps `rag-improve` noise (deleted/empty files, invented needles) out of the gap log.

## Conventions
- New scripts go in `scripts/`. Reuse `rag-eval.py` helpers via `importlib` — don't duplicate HTTP/embed/rerank logic. The side-effect-free A/B harnesses (`verify-case.py`, `rerank-ab.py`, `answer-ab.py`) are the pattern: take args/stdin, print JSON, write nothing.
- `rag.private.conf` (private collections) is tracked in `dotfiles_private` and symlinked here; gitignored in the public repo.

After any change:

```bash
rag status                                   # both services up
rag eval | tail -1                           # dotfiles pass rate stable (other suites: rag eval rag.eval.<collection>.json)
rag improve --dry-run --files-per-run 1      # loop still works
```
