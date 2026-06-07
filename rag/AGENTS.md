# rag — agent rules

- [rag.eval.json](rag.eval.json): hand-written cases (no `"auto"` flag) are read-only for automation. Only `"auto": true` cases are edited by [scripts/rag-improve.py](scripts/rag-improve.py).
- Chunk header `File: <path>\nSummary: <line>\n\n` built in [scripts/rag-ingest.py](scripts/rag-ingest.py) is load-bearing. Touching it invalidates the index → `rag drop <collection> && rag refresh <collection>` required.
- `scripts/rag-improve.py` imports `rag-eval.py` via `importlib` (hyphen filename). Don't rename `embed() search() run_case() check_assertion() http_json()` — the loop breaks silently.
- Lockfile `/tmp/rag-improve.lock` — never spawn parallel `rag improve` runs.
- Depends on `auto` alias in [../litellm/config.yaml](../litellm/config.yaml) `model_group_alias`. Removing it breaks `ai` and `rag improve` defaults.
- Depends on `embed` alias in LiteLLM. Dimension is 2048 — if swapped, re-ingest all collections.
- New scripts go in `scripts/`. Reuse `rag-eval.py` helpers via `importlib` — don't duplicate HTTP/embed logic.

After any change:

```bash
rag status                                   # both services up
rag eval | tail -1                           # pass rate stable
rag improve --dry-run --files-per-run 1      # loop still works
```
