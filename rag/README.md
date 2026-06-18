# RAG — retrieval-augmented knowledge over dotfiles (and beyond)

A client-side toolkit that indexes files into Qdrant and answers questions via LiteLLM. No dedicated container — this module is **code only**. It depends on two shared services living in sibling modules:

- [../litellm/](../litellm/) — chat + embed proxy at `http://localhost:4000`
- [../qdrant/](../qdrant/) — vector DB at `http://localhost:6333`

Both must be running. `rag status` checks both.

## Contents

| File | Purpose |
|---|---|
| `rag.sh` | Main zsh wrapper — defines the `rag` function and zsh completion |
| `rag.conf` | Declarative collections for `rag refresh` — "what lives in which collection" |
| `rag.eval.json` | Regression corpus for the `dotfiles` collection (canonical real file). Other collections: `rag.eval.<collection>.json`, symlinked from `dotfiles_private/rag/` |
| `rag-eval-history.md` | Append-only quality trend (one block per `rag improve` run) |
| `gaps/<collection>.md` | Retrieval/judge failures flagged by `rag improve` — per-collection todo queue. Old aggregated `rag-gaps.md` is kept readable for `rag prune-gaps --legacy`. |
| `rag-retired.md` | Auto-generated cases that hit 3 consecutive strikes and were dropped |
| `scripts/rag-ingest.py` | Chunk files → embed → upsert to Qdrant |
| `scripts/rag-ask.py` | Retrieve → pass context to LiteLLM for answer |
| `scripts/rag-eval.py` | Run the regression corpus |
| `scripts/rag-improve.py` | Autonomous loop: propose new cases, validate, grow corpus |
| `scripts/rag-prune-gaps.py` | Re-run gap entries against current retrieval; drop the ones now closed |
| `scripts/rag-queries.py` | Digest of real queries logged by `rag ask`/`rag context` — mine for new eval cases |
| `scripts/rag-answer-eval.py` | Grade the final LLM answer (GOOD/PARTIAL/BAD), not just whether a chunk was retrieved |
| `scripts/rag-answer-eval-nightly.py` | Cron wrapper: nightly answer-quality gate, Telegram alert on regression |
| `scripts/verify-case.py` | Verify candidate eval cases against live retrieval (same path as `rag eval`); stdin JSON → JSON verdicts |
| `scripts/merge-verified-cases.py` | Re-verify + dedup + merge bulk-generated cases into the right eval files |
| `scripts/rerank-ab.py` | A/B the reranker vs plain hybrid on a suite (verdict: see `docs/retrieval-benchmark.md`) |
| `scripts/answer-ab.py` | A/B answer-generation models, fixed sample, no history side-effects |
| `docs/retrieval-benchmark.md` | Baseline pass rates + reranker/embedder A/B methodology and verdict |
| `logs/queries.jsonl` | Append-only log of every real query (gitignored, per-machine) |
| `scripts/rag-karabiner-summary.py` | Regenerate `karabiner/rules/SUMMARY.md` (dotfiles-specific) |

## Quick start

Default collection is `dotfiles` (override with `RAG_COLLECTION=name` or `--collection name`).

```bash
rag status                           # both services healthy?
rag ask "what does Hyper+V do?"      # retrieve + LLM answer
rag context "Karabiner rules" | pbcopy   # retrieve only, no LLM
rag refresh                          # re-ingest everything in rag.conf
rag eval                             # run regression suite
rag improve --chat-model fast        # autonomous loop (see below)
```

## Subcommands

```
rag ingest  [flags] <path...>       index files/dirs into Qdrant
rag ask     [flags] "question"      retrieve + answer via LiteLLM
rag context [flags] "question"      retrieve only (pipe to pbcopy / review)
rag info    <collection>            show stats + indexed file list
rag refresh [collection]            re-ingest per rag.conf rules
rag list                            list Qdrant collections
rag drop    <collection>            delete a collection (asks confirmation)
rag status                          health of LiteLLM + Qdrant
rag eval    [file] [--verbose]      run canonical regression cases
rag improve [flags]                 autonomous corpus grower (see below)
rag prune-gaps [flags]              drop gap entries the current index now resolves
rag help                            show this help
```

`zsh/bin/rag` is a standalone wrapper — non-zsh callers (Claude Code, Codex bash subshells) can invoke `rag <subcommand>` as a regular command.

**`rag ask --decompose`** — for multi-hop / chained questions, splits the question into sub-questions, retrieves for each, and answers over the union of chunks. One query often misses a later hop (e.g. the Hammerspoon action behind an F-key); decomposing surfaces it. Opt-in: costs one extra LLM call + N retrievals, so leave it off for simple lookups.

## Config — `rag.conf`

Declarative `collection:path(s)` rules used by `rag refresh`:

```
dotfiles: ~/projects/dotfiles --exclude /jetbrains --exclude /images/ ...
```

One line per collection. Paths expand `~`, globs and env vars. Add a new collection: one line, then `rag refresh <name>`.

## Ingester

`scripts/rag-ingest.py` does:

1. Walks paths, filters by extension (md/sh/lua/py/json/yaml/toml/... plus keylayout/plist — see `DEFAULT_EXTENSIONS`).
2. Splits each file into ~1200-char chunks with 150-char overlap (paragraph-aware).
3. **Prepends a `File: <path>\nSummary: <one-liner>\n\n` header to every chunk** — this is the key lift that lets the free embed model disambiguate visually-identical JSON/Lua chunks across many files. Summary is extracted per file type (JSON `description`, Markdown H1, first comment block, etc.).
4. Embeds via LiteLLM `embed` alias, upserts into Qdrant with UUID = hash of `path+chunk_index` (so re-ingest is idempotent).

Useful flags: `--chunk-size`, `--chunk-overlap`, `--extensions`, `--exclude`, `--max-files`, `--source`.

## Eval

`rag.eval.json` is a hand-written + auto-generated corpus of `{q, must_contain}` or `{q, must_hit_path}` cases. Each case asserts that the top-k retrieval surfaces a chunk containing the expected substring.

```bash
rag eval                 # ≥95% pass is the bar
rag eval --verbose       # show retrieved paths on failures
```

The pipeline (`scripts/rag-eval.py`) exposes `embed()`, `search()`, `run_case()` as importable helpers — `rag-improve.py` imports them directly so logic stays in one place.

## Autonomous improvement loop

`rag improve` is a self-hosted feedback loop that consumes free-LiteLLM quota to grow and police the eval corpus — no Claude, no manual effort.

### Per-run pipeline

1. **Sample** 5 files: 60% recently git-changed in `~/projects/dotfiles/` (via `git log --since='7 days ago'`), 40% uniform random from the Qdrant index. Seeded by date → same-day reruns converge.
2. **Build a context pack** per file: primary content + sibling summaries + nearest `SUMMARY.md` / `README.md` + top-5 semantic neighbours from Qdrant + `git grep` referrers. Up to ~20K chars.
3. **Propose** `--cases-per-file` test cases via chat model (default `coder`). Prompt requests cross-file questions and strict JSON output.
4. **Validate** through four gates:
   - syntactic (length, no tautologies, must_contain is literal substring of pack)
   - retrieval-must-hit (proposal embeds and actually pulls the chunk)
   - **LLM-as-judge** (sees only retrieved chunks, not the pack — cannot rubber-stamp): verdicts `OK` / `WRONG` / `UNCLEAR`
5. **Commit** accepted cases to `rag.eval.json` with `"auto": true`, `"origin"`, `"added"`, `"strikes": 0`. Rejected → `gaps/<collection>.md`. Judge upstream failures (`(judge unavailable)`) are counted separately and not logged as gaps — they're transport noise, not retrieval signal.
6. **Revisit** 10 old `auto` cases. Pass → `strikes = 0`. Fail → `strikes += 1`. At 3 strikes → retire to `rag-retired.md`.
7. **Prune gaps** in `gaps/<collection>.md`: re-run each entry through retrieval, drop the ones whose `expect` substring is now in top-k. Embed upstream failures keep the entry (decision deferred). Disable with `--no-prune-gaps`.
8. **Full eval** sweep, results appended to `rag-eval-history.md`.

Per-collection lockfile `/tmp/rag-improve.<collection>.lock` prevents concurrent runs of the same collection (different collections can run in parallel).

### Invocation

```bash
rag improve                          # normal run — dotfiles collection (rag.eval.json)
rag improve --collection serho       # one other collection (auto-picks rag.eval.serho.json)
rag improve --all --rotate 2         # rotate through ALL collections, 2 per run (cursor in /tmp/rag-improve.rotation.json)
rag improve --dry-run                # propose+judge but don't write
rag improve --files-per-run 10       # bigger burst
rag improve --chat-model fast        # Groq group, ~1-3s per call
rag improve --no-revisit --no-git    # selectively disable phases
```

Gaps are only logged for a real source file (exists, non-empty) whose `expect` substring literally occurs in it — deleted/empty files and invented needles are dropped, not queued.

### Pruning the gap log

The prune phase runs automatically inside each `rag improve` cycle (step 7
above) — so `gaps/<collection>.md` self-cleans as retrieval improves. New
entries that the next ingest/chunker change can answer disappear on the
following cron tick.

For the one-off legacy aggregate `rag-gaps.md` (pre-dating per-collection
split), and for ad-hoc runs:

```bash
rag prune-gaps --dry-run              # report what would drop, write nothing
rag prune-gaps                        # rewrite gaps/<collection>.md in place
rag prune-gaps --legacy --dry-run     # also sweep the old aggregated rag-gaps.md
```

A gap is considered closed when any chunk in the current top-k retrieval for
the original question contains the recorded `expect` substring (text or path).
Embed upstream failures are treated as "decision deferred" — entries are kept.

## Real queries → eval cases

`rag ask` / `rag context` log every query to `logs/queries.jsonl`. These are the
highest-signal source of eval cases — the questions you actually ask beat the
ones the auto-loop invents. Review them and convert the good ones:

```bash
rag queries              # deduped digest, weak (0-hit / refused) on top
rag queries --weak       # just the work queue
```

To turn a query into an eval case: pick it, find a stable substring in the right
source file, add `{q, must_contain, manual: true}` to `rag.eval.json`. Manual
cases are never auto-retired — they're the reliable backbone of the corpus.

## Answer-quality eval (not just retrieval)

`rag eval` only checks whether a chunk containing the gold substring was
retrieved. It says nothing about whether the final answer is correct. `rag
answer-eval` closes that gap — retrieve → answer → judge GOOD/PARTIAL/BAD:

```bash
rag answer-eval --manual-only --verbose          # grade your hand-written cases
rag answer-eval --sample 30                       # broader sample
```

Defaults (set by A/B, 2026-06-17): answer model `gpt` (what `rag ask` serves),
judge `github-gpt4o-mini` (non-reasoning → clean verdicts, no `<think>` leak),
top-10 chunks of context (matches `rag ask`). The old `fast/fast` default was an
unreliable grader, not a real quality signal. Bypasses LiteLLM's semantic cache
so grades reflect a fresh answer. Appends to `rag-answer-eval-history.md`.

A cron wrapper [scripts/rag-answer-eval-nightly.py](scripts/rag-answer-eval-nightly.py)
runs a small nightly sample per collection and sends a Telegram alert if a
collection's quality score regresses (drop >15pp or below a floor).

## Index hygiene

Two defects found via answer-eval, both fixed in `rag.conf` / scripts:

- **Eval corpus pollution** — `rag.eval.json`, `gaps/`, `rag-*-history.md` were
  being ingested into the `dotfiles` collection, so questions *about* the
  dotfiles retrieved the eval data itself. Now excluded in `rag.conf`.
- **Semantic-cache cross-match** — LiteLLM's semantic cache matches by embedding
  similarity, so it can return a cached completion from a *different* prompt that
  shares context chunks (e.g. a `rag improve` PROPOSE prompt, or one ask leaking
  into another). This was poisoning real `rag ask` answers (asked about margin →
  got an answer about order types; asked about routing → got eval-case JSON).
  Fixed: `rag ask` and `rag answer-eval` now both send `cache: {no-cache}`. Any
  new chat call on an answer path must do the same.

### Cron (opt-in)

Installed by `../cron/init-cron-jobs.sh` from [../cron/cron_jobs/rag-improve.cron](../cron/cron_jobs/rag-improve.cron) and `rag-answer-eval.private.cron`:

```
0  * * * * rag-improve.py                          # dotfiles, hourly
30 * * * * rag-improve.py --all --rotate 2         # rotate other collections, hourly at :30
30 3 * * * rag-answer-eval-nightly.py              # nightly answer-quality gate + Telegram alert
```

~15 chat + ~130 embed calls per collection-run; free quota handles this trivially. Per-collection lockfiles keep the two `rag-improve` lines from colliding.

### After a week

- Eval suites grown across all 10 collections (≈2.5k cases total) reflecting files you actually touched.
- `gaps/<collection>.md` — todo queue of retrieval weak spots. Each entry suggests a place to write a SUMMARY.md or tune the chunker.
- `rag-eval-history.md` — quality dashboard. Any regression is immediately visible.
- `rag-retired.md` — cases that decayed. Points to drift (deleted files, chunker changes, upstream flakiness).

## Writing SUMMARY.md to help retrieval

The single highest-ROI improvement for a weak area is a hand-written `SUMMARY.md` in its directory. The ingester walks parents looking for `SUMMARY.md` / `README.md` / `CLAUDE.md` / `AGENTS.md` when building context packs, so one good summary radiates semantic signal across all the area's files.

Examples in this repo: [../karabiner/rules/SUMMARY.md](../karabiner/rules/SUMMARY.md), [../keyboard-layout/SUMMARY.md](../keyboard-layout/SUMMARY.md).

## Env vars

Shared across all scripts:

- `LITELLM_URL` — default `http://localhost:4000`
- `LITELLM_MASTER_KEY` — default `sk-local-workbot`
- `QDRANT_URL` — default `http://localhost:6333`
- `RAG_EMBED_MODEL` — default `embed`
- `RAG_CHAT_MODEL` — default `gpt`
- `RAG_COLLECTION` — default `workflow` (you probably want `dotfiles` — set it in `openai_key.sh`)
