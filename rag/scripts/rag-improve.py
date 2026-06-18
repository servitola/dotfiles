#!/usr/bin/env python3
"""rag-improve — autonomous loop that grows and vets the RAG regression corpus.

Each run:
  1. Samples N files from the dotfiles repo (60% recent git-changed, 40% random)
  2. Builds a 5-section context pack per file
  3. Asks a free chat model to propose test cases with must_contain anchors
  4. Validates proposals: syntactic → literal-substring-in-pack → retrieval-hit
  5. Runs an LLM-as-judge on the retrieved chunks (not the pack) for final OK/WRONG
  6. Commits accepted cases to rag.eval.json with `"auto": true` metadata
  7. Revisits 10 old auto cases, increments strikes on failure, retires at 3
  8. Runs the full eval, appends one block to rag-eval-history.md

Gaps (retrieval miss or judge rejection) land in rag-gaps.md.
Retired cases (3 strikes) land in rag-retired.md.

Works per-collection: --collection picks the target and its matching eval file
(rag.eval.json for 'dotfiles', rag.eval.<collection>.json otherwise). --all
rotates through every collection declared in rag.conf + rag.private.conf,
tending --rotate of them per invocation (round-robin via a /tmp cursor) so a
single run stays within free-tier quota. Each collection uses its own lockfile
(/tmp/rag-improve.<collection>.lock) so they never block one another.

Invocation:
  rag improve                                  # dotfiles (default, unchanged)
  rag improve --collection sphere              # one other collection
  rag improve --all                            # rotate --rotate collections
  rag improve --all --rotate 3 --dry-run
  rag improve --dry-run
  rag improve --files-per-run 10
  rag improve --chat-model fast
  rag improve --no-revisit --no-git
"""

from __future__ import annotations

import argparse
import datetime
import fcntl
import hashlib
import importlib.machinery
import importlib.util
import json
import os
import random
import re
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path
from types import ModuleType

# ----------------------------------------------------------------------------
# Module loaders — sibling scripts use hyphens in filenames, can't direct-import
# ----------------------------------------------------------------------------

SCRIPTS_DIR = Path(__file__).resolve().parent


def _load_module(name: str, file: str) -> ModuleType:
    loader = importlib.machinery.SourceFileLoader(name, str(SCRIPTS_DIR / file))
    spec = importlib.util.spec_from_loader(name, loader)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {file}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


rag_eval = _load_module("rag_eval", "rag-eval.py")
rag_ingest = _load_module("rag_ingest", "rag-ingest.py")
rag_prune_gaps = _load_module("rag_prune_gaps", "rag-prune-gaps.py")


# ----------------------------------------------------------------------------
# Paths & constants
# ----------------------------------------------------------------------------

DOTFILES_ROOT = Path.home() / "projects" / "dotfiles"
RAG_ROOT = DOTFILES_ROOT / "rag"
EVAL_FILE = RAG_ROOT / "rag.eval.json"  # set per collection in run_collection()

# Root of the repo being improved this run. Defaults to dotfiles, set per
# collection in run_collection() from rag.conf. Used by git log, git grep, and
# path-relative reporting in stats / gaps / origin fields.
CURRENT_REPO_ROOT: Path = DOTFILES_ROOT
HISTORY_FILE = RAG_ROOT / "rag-eval-history.md"
# Legacy single-file location, kept readable for the prune tool. New gaps go
# under rag/gaps/<collection>.md — see gaps_file_for().
GAPS_FILE_LEGACY = RAG_ROOT / "rag-gaps.md"
GAPS_DIR = RAG_ROOT / "gaps"
RETIRED_FILE = RAG_ROOT / "rag-retired.md"
RAG_CONF = RAG_ROOT / "rag.conf"
RAG_PRIVATE_CONF = RAG_ROOT / "rag.private.conf"  # gitignored, same format as rag.conf
# Round-robin cursor for `--all`: which collections were tended last invocation.
# Small JSON ({"cursor": <int>}); lets each hourly run advance a few collections
# instead of hammering all of them. See pick_rotation() / advance_rotation().
ROTATION_STATE = Path("/tmp/rag-improve.rotation.json")
LOCKFILE = Path("/tmp/rag-improve.lock")  # mutated in main() per --collection


def gaps_file_for(collection: str) -> Path:
    """Per-collection gap log. Created lazily by append_gap()."""
    return GAPS_DIR / f"{collection}.md"

# Substring excludes for the active collection, populated in run_collection() from rag.conf.
# Used by _is_indexable() so that proposer never sees files that ingest skipped —
# otherwise the loop generates retrieval-miss noise for non-indexed paths.
_EXCLUDES: list[str] = []

NARRATIVE_NAMES = ("SUMMARY.md", "README.md", "CLAUDE.md", "AGENTS.md")

STOPWORDS = {
    "the", "function", "file", "value", "path", "name", "type",
    "true", "false", "null", "return", "hyper", "key", "code",
}

SKIP_FILENAMES = {"SUMMARY.md", "README.md"}


# ----------------------------------------------------------------------------
# Args
# ----------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Autonomous RAG improvement loop.")
    p.add_argument("--collection", default=os.environ.get("RAG_COLLECTION", "dotfiles"))
    p.add_argument("--all", action="store_true",
                   help="Tend every collection declared in rag.conf + rag.private.conf, "
                        "ROTATING --rotate of them per invocation (round-robin via "
                        f"{ROTATION_STATE}). Ignores --collection / --eval-file.")
    p.add_argument("--rotate", type=int, default=2,
                   help="With --all: how many collections to process this invocation "
                        "(round-robin). Default 2 — keeps per-run quota modest at the "
                        "hourly cadence (10 collections => full sweep every ~5 hours).")
    p.add_argument("--eval-file", default=None,
                   help="Path to the rag.eval.*.json for this collection. Default is derived "
                        "from --collection: rag/rag.eval.json for 'dotfiles', "
                        "rag/rag.eval.<collection>.json otherwise.")
    p.add_argument("--files-per-run", type=int, default=5)
    p.add_argument("--cases-per-file", type=int, default=2)
    p.add_argument("--chat-model", default="coding")
    p.add_argument("--judge-model", default=os.environ.get("RAG_JUDGE_MODEL", "fast"),
                   help="Model used for the LLM-as-judge step. Default 'fast' (Groq rotation) — "
                        "more stable than 'coding' under cron-driven 2h cadence.")
    p.add_argument("--top-k", type=int, default=12)
    p.add_argument("--revisit-sample", type=int, default=10)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--no-revisit", action="store_true")
    p.add_argument("--no-git", action="store_true")
    p.add_argument("--no-final-eval", action="store_true", help="Skip full-eval sweep at the end")
    p.add_argument("--no-prune-gaps", action="store_true",
                   help="Skip the gap-prune phase (rag/gaps/<collection>.md). "
                        "Pruning drops entries whose `expect` substring is now in top-k.")
    p.add_argument("--use-claude-cli", action="store_true",
                   help="Route chat() through the local `claude` CLI (subscription auth) "
                        "instead of LiteLLM. Use with --chat-model claude-opus-4-7.")
    p.add_argument("--claude-cli-budget-usd", type=float, default=15.0,
                   help="Total spend cap (USD) for the run when --use-claude-cli is set. "
                        "Aborts further calls once exceeded. Default: 15.0")
    return p.parse_args()


# ----------------------------------------------------------------------------
# Locking
# ----------------------------------------------------------------------------

def acquire_lock():
    fd = open(LOCKFILE, "w")
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        fd.close()
        return None
    fd.write(f"{os.getpid()}\n")
    fd.flush()
    return fd


# ----------------------------------------------------------------------------
# LiteLLM chat wrapper (rag_eval already has embed/search/run_case)
# ----------------------------------------------------------------------------

def _chat_litellm(prompt: str, model: str, max_tokens: int, retries: int) -> str | None:
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
    }
    headers = {"Authorization": f"Bearer {rag_eval.LITELLM_MASTER_KEY}"}
    for attempt in range(retries + 1):
        try:
            data = rag_eval.http_json("POST", f"{rag_eval.LITELLM_URL}/v1/chat/completions",
                                     payload=payload, headers=headers)
            msg = data.get("choices", [{}])[0].get("message", {})
            return msg.get("content") or msg.get("reasoning_content") or ""
        except SystemExit as exc:
            err = str(exc)
            if any(code in err for code in ("HTTP 429", "HTTP 404", "HTTP 5")):
                if attempt < retries:
                    time.sleep(2 * (attempt + 1))
                    continue
            return None
    return None


# Tracker for per-process spend when routing through claude CLI.
_CLAUDE_CLI_TOTAL_USD = 0.0
_CLAUDE_CLI_BUDGET_USD: float | None = None  # set in main() if --use-claude-cli
_CLAUDE_CLI_PER_CALL_USD = 1.00


def _chat_claude_cli(prompt: str, model: str, max_tokens: int, retries: int) -> str | None:
    """Route a chat call through the local `claude` CLI (subscription auth).

    `--bare` is incompatible with subscription, so we run with default auth.
    Default system prompt still loads ~20K cache-creation tokens per call,
    that's the price of running through the CLI vs raw API.
    """
    global _CLAUDE_CLI_TOTAL_USD
    if _CLAUDE_CLI_BUDGET_USD is not None and _CLAUDE_CLI_TOTAL_USD >= _CLAUDE_CLI_BUDGET_USD:
        print(f"  claude-cli: budget reached (${_CLAUDE_CLI_TOTAL_USD:.2f} / "
              f"${_CLAUDE_CLI_BUDGET_USD:.2f}), skipping call", file=sys.stderr)
        return None

    cmd = [
        "claude", "-p",
        "--model", model,
        "--output-format", "json",
        "--tools", "",
        "--no-session-persistence",
        "--max-budget-usd", f"{_CLAUDE_CLI_PER_CALL_USD:.2f}",
        "--system-prompt", "You are a chat completion endpoint. Respond directly to the user message. No tools, no commentary, no markdown fences unless the user asks.",
    ]
    for attempt in range(retries + 1):
        try:
            proc = subprocess.run(
                cmd, input=prompt, text=True, capture_output=True,
                timeout=120, cwd="/tmp",  # /tmp avoids picking up project CLAUDE.md
            )
        except subprocess.TimeoutExpired:
            if attempt < retries:
                time.sleep(2 * (attempt + 1))
                continue
            return None

        if proc.returncode != 0 and not proc.stdout.strip():
            if attempt < retries:
                time.sleep(2 * (attempt + 1))
                continue
            return None

        try:
            data = json.loads(proc.stdout.strip().splitlines()[-1])
        except (json.JSONDecodeError, IndexError):
            return None

        cost = float(data.get("total_cost_usd") or 0.0)
        _CLAUDE_CLI_TOTAL_USD += cost
        text = data.get("result") or ""

        # Budget hits return is_error=true with a polite message in `result` —
        # treat as soft failure so judge gets UNCLEAR rather than garbage.
        if data.get("is_error"):
            errs = data.get("errors") or []
            if any("budget" in e.lower() for e in errs):
                print(f"  claude-cli: per-call budget hit (${cost:.3f})", file=sys.stderr)
            return None
        return text
    return None


def chat(prompt: str, model: str = "coding", max_tokens: int = 1500, retries: int = 2) -> str | None:
    if _CLAUDE_CLI_BUDGET_USD is not None:
        return _chat_claude_cli(prompt, model, max_tokens, retries)
    return _chat_litellm(prompt, model, max_tokens, retries)


# ----------------------------------------------------------------------------
# File pools (git + qdrant)
# ----------------------------------------------------------------------------

def _is_indexable(p: Path) -> bool:
    if not (
        p.is_file()
        and p.suffix.lower() in rag_ingest.DEFAULT_EXTENSIONS
        and p.name not in SKIP_FILENAMES
        and ".git" not in p.parts
        and "qdrant_storage" not in p.parts
    ):
        return False
    if _EXCLUDES:
        s = str(p)
        if any(ex in s for ex in _EXCLUDES):
            return False
    return True


def load_collection_config(collection: str, conf: Path = RAG_CONF) -> tuple[Path | None, list[str]]:
    """Parse rag.conf for a collection, return (root_path, excludes).

    Mirrors the shell parser in rag.sh's `refresh` branch:
      <name>: <path...> --exclude X --exclude Y ...

    Returns (None, []) if the collection is not in rag.conf.
    """
    if not conf.exists():
        return None, []
    for raw in conf.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line or ":" not in line:
            continue
        name, _, rest = line.partition(":")
        if name.strip() != collection:
            continue
        toks = rest.split()
        excludes: list[str] = []
        root: str | None = None
        i = 0
        while i < len(toks):
            if toks[i] == "--exclude" and i + 1 < len(toks):
                excludes.append(toks[i + 1])
                i += 2
            else:
                if root is None:
                    root = toks[i]
                i += 1
        root_path = Path(os.path.expanduser(root)).resolve() if root else None
        return root_path, excludes
    return None, []


def load_excludes_for_collection(collection: str, conf: Path = RAG_CONF) -> list[str]:
    """Backwards-compat shim — returns just the excludes."""
    _, excludes = load_collection_config(collection, conf)
    return excludes


def default_eval_file_for(collection: str) -> Path:
    """Per-collection regression suite path.

    `dotfiles` keeps the historical default `rag.eval.json` (so nothing relying
    on it breaks); every other collection uses `rag.eval.<collection>.json`.
    """
    if collection == "dotfiles":
        return RAG_ROOT / "rag.eval.json"
    return RAG_ROOT / f"rag.eval.{collection}.json"


def discover_collections() -> list[str]:
    """All collection names declared in rag.conf + rag.private.conf, in file
    order (rag.conf first), de-duplicated. This is the canonical `--all` set —
    collections with a known source path. Drives round-robin rotation."""
    names: list[str] = []
    seen: set[str] = set()
    for conf in (RAG_CONF, RAG_PRIVATE_CONF):
        if not conf.exists():
            continue
        for raw in conf.read_text(encoding="utf-8").splitlines():
            line = raw.split("#", 1)[0].strip()
            if not line or ":" not in line:
                continue
            name = line.partition(":")[0].strip()
            if name and name not in seen:
                seen.add(name)
                names.append(name)
    return names


def _read_rotation_cursor() -> int:
    try:
        return int(json.loads(ROTATION_STATE.read_text(encoding="utf-8")).get("cursor", 0))
    except (OSError, ValueError, json.JSONDecodeError):
        return 0


def _write_rotation_cursor(cursor: int) -> None:
    try:
        ROTATION_STATE.write_text(json.dumps({"cursor": cursor}) + "\n", encoding="utf-8")
    except OSError:
        pass  # best-effort; a missing state file just restarts rotation at 0


def pick_rotation(collections: list[str], n: int) -> tuple[list[str], int]:
    """Pick the next `n` collections round-robin from the persisted cursor.

    Returns (picked, next_cursor). Wraps around the list so over many runs every
    collection is tended evenly without ever processing all of them at once.
    """
    if not collections:
        return [], 0
    n = max(1, min(n, len(collections)))
    start = _read_rotation_cursor() % len(collections)
    picked = [collections[(start + i) % len(collections)] for i in range(n)]
    return picked, (start + n) % len(collections)


def get_recent_files(days: int = 7) -> list[Path]:
    try:
        out = subprocess.check_output(
            ["git", "-C", str(CURRENT_REPO_ROOT), "log",
             f"--since={days} days ago", "--name-only",
             "--diff-filter=ACMR", "--pretty=format:"],
            stderr=subprocess.DEVNULL, text=True, timeout=15,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return []
    seen: set[str] = set()
    result: list[Path] = []
    for line in out.splitlines():
        rel = line.strip()
        if not rel or rel in seen:
            continue
        seen.add(rel)
        p = CURRENT_REPO_ROOT / rel
        if _is_indexable(p):
            result.append(p)
    return result


def get_indexed_files(collection: str) -> list[Path]:
    """Scroll Qdrant for unique payload.path values."""
    seen: set[str] = set()
    offset = None
    for _ in range(50):  # scroll cap
        payload = {"limit": 500, "with_payload": ["path"], "with_vector": False}
        if offset is not None:
            payload["offset"] = offset
        data = rag_eval.http_json(
            "POST",
            f"{rag_eval.QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points/scroll",
            payload=payload,
        )
        result = data.get("result", {})
        for point in result.get("points", []):
            p = (point.get("payload") or {}).get("path")
            if p:
                seen.add(p)
        offset = result.get("next_page_offset")
        if not offset:
            break
    paths = []
    for s in seen:
        p = Path(s)
        if _is_indexable(p):
            paths.append(p)
    return paths


def sample_files(recent: list[Path], indexed: list[Path], n_total: int, seed: str) -> list[Path]:
    rng = random.Random(seed)
    n_recent = min(len(recent), round(n_total * 0.6))
    recent_pick = rng.sample(recent, n_recent) if n_recent else []
    chosen = set(recent_pick)
    pool = [p for p in indexed if p not in chosen]
    n_random = min(n_total - len(recent_pick), len(pool))
    random_pick = rng.sample(pool, n_random) if n_random else []
    return recent_pick + random_pick


# ----------------------------------------------------------------------------
# Context pack
# ----------------------------------------------------------------------------

def _read_text(p: Path, max_bytes: int = 50_000) -> str:
    try:
        text = p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""
    return text[:max_bytes]


def _primary_section(path: Path, budget: int = 8000) -> str:
    text = _read_text(path)
    if len(text) <= budget:
        return text
    head_cap = int(budget * 0.625)
    tail_cap = budget - head_cap
    return text[:head_cap] + "\n\n[... middle truncated ...]\n\n" + text[-tail_cap:]


def _sibling_summaries(path: Path, cap: int = 40) -> list[str]:
    out: list[str] = []
    for sib in sorted(path.parent.iterdir()):
        if sib == path or not sib.is_file():
            continue
        if sib.suffix.lower() not in rag_ingest.DEFAULT_EXTENSIONS:
            continue
        text = _read_text(sib, max_bytes=4000)
        if not text:
            continue
        summary = rag_ingest._extract_summary(sib, text)
        out.append(f"- {sib.name}: {summary}")
        if len(out) >= cap:
            break
    return out


def _nearest_narrative(path: Path, max_bytes: int = 4000) -> tuple[str, str] | None:
    for parent in path.parents:
        for name in NARRATIVE_NAMES:
            cand = parent / name
            if cand.is_file() and cand != path:
                text = _read_text(cand, max_bytes=max_bytes + 200)
                if len(text) > max_bytes:
                    text = text[:max_bytes] + "\n[... truncated ...]"
                rel = str(cand.relative_to(CURRENT_REPO_ROOT)) if cand.is_relative_to(CURRENT_REPO_ROOT) else str(cand)
                return rel, text
        if (parent / ".git").exists():
            break
    return None


def _semantic_neighbours(path: Path, collection: str, top_k: int = 5) -> list[dict]:
    text = _read_text(path, max_bytes=8000)
    summary = rag_ingest._extract_summary(path, text)
    query = f"{path.name}: {summary}"
    vec = rag_eval.embed(query)
    if vec is None:
        return []
    hits = rag_eval.search(collection, vec, top_k * 3)
    same = str(path)
    out = []
    for h in hits:
        pth = h.get("payload", {}).get("path")
        if pth == same:
            continue
        out.append(h)
        if len(out) >= top_k:
            break
    return out


def _explicit_referrers(path: Path, limit: int = 5) -> list[tuple[str, str]]:
    try:
        out = subprocess.check_output(
            ["git", "-C", str(CURRENT_REPO_ROOT), "grep", "-l", "--fixed-strings", path.name, "--"],
            stderr=subprocess.DEVNULL, text=True, timeout=10,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return []
    self_rel = str(path.relative_to(CURRENT_REPO_ROOT)) if path.is_relative_to(CURRENT_REPO_ROOT) else str(path)
    snippets: list[tuple[str, str]] = []
    for rel in out.splitlines():
        rel = rel.strip()
        if not rel or rel == self_rel:
            continue
        full = CURRENT_REPO_ROOT / rel
        text = _read_text(full, max_bytes=20_000)
        if not text:
            continue
        idx = text.find(path.name)
        if idx < 0:
            continue
        start = max(0, idx - 100)
        end = min(len(text), idx + 100)
        snippets.append((rel, text[start:end]))
        if len(snippets) >= limit:
            break
    return snippets


def build_context_pack(path: Path, collection: str) -> tuple[str, str]:
    """Returns (pack_text, pack_lower). pack_lower used for substring validation."""
    rel = str(path.relative_to(CURRENT_REPO_ROOT)) if path.is_relative_to(CURRENT_REPO_ROOT) else str(path)
    full_text = _read_text(path)
    summary = rag_ingest._extract_summary(path, full_text)  # summary from full text (JSON parses etc.)
    primary = _primary_section(path)

    parts: list[str] = []
    parts.append("========= PRIMARY FILE =========")
    parts.append(f"Path: {rel}")
    parts.append("Ingester header (what retrieval actually embeds):")
    parts.append(f"File: {rel}")
    parts.append(f"Summary: {summary}")
    parts.append("\nContent:")
    parts.append("<<<")
    parts.append(primary)
    parts.append(">>>")

    sibs = _sibling_summaries(path)
    if sibs:
        parts.append("\n========= SIBLING FILES =========")
        parts.extend(sibs)

    narr = _nearest_narrative(path)
    if narr:
        narr_rel, narr_text = narr
        parts.append("\n========= NEAREST NARRATIVE DOC =========")
        parts.append(f"(from {narr_rel})")
        parts.append(narr_text)

    neigh = _semantic_neighbours(path, collection)
    if neigh:
        parts.append("\n========= SEMANTIC NEIGHBOURS =========")
        for h in neigh:
            pl = h.get("payload", {})
            npath = pl.get("path", "?")
            ntext = (pl.get("text") or "")[:800]
            parts.append(f"[path={npath}]")
            parts.append(ntext)
            parts.append("---")

    refs = _explicit_referrers(path)
    if refs:
        parts.append("\n========= EXPLICIT REFERRERS =========")
        for rrel, snippet in refs:
            parts.append(f"[{rrel}]")
            parts.append(f"  …{snippet.replace(chr(10), ' ')}…")

    pack = "\n".join(parts)
    return pack, pack.lower()


# ----------------------------------------------------------------------------
# Proposal / validation / judge
# ----------------------------------------------------------------------------

PROPOSE_PROMPT_TMPL = """You generate RAG regression tests for a personal dotfiles repository.

{pack}

========= TASK =========
Propose {n} specific questions a user might realistically ask about this area,
each with ONE distinctive substring ("must_contain") that appears VERBATIM in
ANY of the sections above and would appear in any correct retrieved chunk.

Strict rules:
- No generic "what is this file about?" questions.
- Mix single-file and cross-file questions naturally — only stitch sections when
  they really are connected. Do NOT invent relationships between unrelated files.
- must_contain is a verbatim case-insensitive substring of the shown content,
  at least 3 chars, not a stopword (the/function/file/value/path/name/type/true/false/null).
- At least one question in Russian, at least one in English.
- Output ONLY a JSON array. No prose, no markdown fences.

Schema: [{{"q": string, "must_contain": string}}]
"""


def parse_proposals(raw: str) -> list[dict]:
    if not raw:
        return []
    s = raw.strip()
    s = re.sub(r"^```(?:json)?\s*\n?", "", s)
    s = re.sub(r"\n?```\s*$", "", s)
    m = re.search(r"\[.*\]", s, re.DOTALL)
    if not m:
        return []
    try:
        arr = json.loads(m.group(0))
    except json.JSONDecodeError:
        return []
    if not isinstance(arr, list):
        return []
    out = []
    for item in arr:
        if not isinstance(item, dict):
            continue
        q = item.get("q") or item.get("question")
        mc = item.get("must_contain") or item.get("mustContain")
        if isinstance(q, str) and isinstance(mc, str):
            out.append({"q": q.strip(), "must_contain": mc.strip()})
    return out


def _norm_q(q: str) -> str:
    return " ".join(q.lower().split())


def validate_proposal(p: dict, pack_lower: str, filename: str, existing_hashes: set[str]) -> tuple[bool, str]:
    q = p.get("q", "")
    mc = p.get("must_contain", "")
    if len(q) < 30:
        return False, "question too short"
    if filename.lower() in q.lower():
        return False, "question mentions filename verbatim"
    if len(mc) < 3:
        return False, "must_contain too short"
    if mc.lower() in STOPWORDS:
        return False, f"must_contain is stopword ({mc!r})"
    if mc.lower() not in pack_lower:
        return False, f"must_contain not in pack (likely hallucination: {mc!r})"
    h = hashlib.sha1(_norm_q(q).encode()).hexdigest()
    if h in existing_hashes:
        return False, "duplicate question"
    return True, ""


JUDGE_PROMPT_TMPL = """A retrieval system was asked: "{q}"

It returned these chunks (top-5 by similarity):
---
{chunks}
---

Do these chunks contain the actual answer to the question? Reply with one of:
  OK — at least one chunk answers the question correctly
  WRONG — chunks are topically close but don't actually answer
  UNCLEAR — retrieved chunks are off-topic

Output one word (OK / WRONG / UNCLEAR), then a colon and one short sentence.
"""


def judge(question: str, hits: list[dict], model: str) -> tuple[str, str]:
    if not hits:
        return "UNCLEAR", "no chunks"
    chunks_blocks = []
    for i, h in enumerate(hits[:5], 1):
        pl = h.get("payload", {})
        pth = pl.get("path", "?")
        text = (pl.get("text") or "")[:800]
        chunks_blocks.append(f"[Chunk {i}: path={pth}]\n{text}")
    prompt = JUDGE_PROMPT_TMPL.format(q=question, chunks="\n\n---\n\n".join(chunks_blocks))
    resp = chat(prompt, model=model, max_tokens=200, retries=4)
    if not resp:
        return "UNCLEAR", "(judge unavailable)"
    first_line = resp.strip().splitlines()[0] if resp.strip() else ""
    parts = first_line.split(":", 1)
    verdict = parts[0].strip().upper()
    if verdict not in ("OK", "WRONG", "UNCLEAR"):
        m = re.search(r"\b(OK|WRONG|UNCLEAR)\b", resp, re.IGNORECASE)
        verdict = m.group(1).upper() if m else "UNCLEAR"
    reason = parts[1].strip() if len(parts) > 1 else resp.strip()[:200]
    return verdict, reason


# ----------------------------------------------------------------------------
# Revisit old auto cases
# ----------------------------------------------------------------------------

def revisit_auto_cases(eval_data: dict, collection: str, top_k: int, n_sample: int, seed: str) -> dict:
    cases = eval_data["cases"]
    auto_idx = [i for i, c in enumerate(cases) if c.get("auto")]
    if not auto_idx:
        return {"checked": 0, "strikes_added": 0, "retired": 0, "retired_cases": []}
    rng = random.Random(seed + "revisit")
    sample = rng.sample(auto_idx, min(n_sample, len(auto_idx)))

    strikes_added = 0
    to_remove: list[int] = []
    retired_cases: list[dict] = []
    for i in sample:
        c = cases[i]
        status, _, reason = rag_eval.run_case(c, collection, top_k)
        if status == "pass":
            c["strikes"] = 0
        elif status == "fail":
            c["strikes"] = c.get("strikes", 0) + 1
            strikes_added += 1
            if c["strikes"] >= 3:
                to_remove.append(i)
                retired_cases.append({**c, "retire_reason": reason})
        # skip: leave alone

    for i in sorted(to_remove, reverse=True):
        cases.pop(i)

    return {
        "checked": len(sample),
        "strikes_added": strikes_added,
        "retired": len(retired_cases),
        "retired_cases": retired_cases,
    }


# ----------------------------------------------------------------------------
# Writers (atomic eval.json, append-only logs)
# ----------------------------------------------------------------------------

def save_eval_atomic(data: dict) -> None:
    tmp = EVAL_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.replace(tmp, EVAL_FILE)


def ensure_log(path: Path, header: str) -> None:
    if not path.exists():
        path.write_text(header, encoding="utf-8")


def append_gap(primary: Path, proposal: dict, hits: list[dict], reason: str,
               collection: str) -> None:
    # Guard against noise: a gap is only real when the source file still exists,
    # is non-empty, and the expected substring actually occurs in it. Proposals
    # occasionally reference a since-deleted or empty file, or invent an `expect`
    # whose wording isn't a literal substring of the source (e.g. "PNG download"
    # when the file says "Download PNG"). Those are bad proposals, not retrieval
    # deficiencies, and must not pollute the gap log — drop them silently.
    needle = proposal.get("must_contain")
    if needle:
        try:
            src_text = primary.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            return  # source unreadable / deleted -> not a real gap
        if not src_text.strip() or needle.lower() not in src_text.lower():
            return  # empty source or invented needle -> not a real gap
    GAPS_DIR.mkdir(parents=True, exist_ok=True)
    gaps_file = gaps_file_for(collection)
    ensure_log(gaps_file, f"# RAG gaps — {collection} — cases that failed retrieval or judge\n\n")
    date = datetime.date.today().isoformat()
    rel = str(primary.relative_to(CURRENT_REPO_ROOT)) if primary.is_relative_to(CURRENT_REPO_ROOT) else str(primary)
    top3 = [h.get("payload", {}).get("path", "?") for h in hits[:3]]
    entry = [
        f"- [{date}] file=`{rel}`",
        f'  Q: "{proposal["q"]}"  expect="{proposal["must_contain"]}"',
        f"  reason: {reason}",
        f"  top-3: {' | '.join(top3) if top3 else '(none)'}",
        "",
    ]
    with gaps_file.open("a", encoding="utf-8") as f:
        f.write("\n".join(entry))


def append_retired(case: dict) -> None:
    ensure_log(RETIRED_FILE, "# RAG retired — auto cases that hit 3 strikes\n\n")
    date = datetime.date.today().isoformat()
    entry = [
        f"- [{date}] origin=`{case.get('origin', '?')}`",
        f'  Q: "{case["q"]}"  expect="{case.get("must_contain", "?")}"',
        f"  last reason: {case.get('retire_reason', '(unknown)')}",
        f"  originally added: {case.get('added', '?')}",
        "",
    ]
    with RETIRED_FILE.open("a", encoding="utf-8") as f:
        f.write("\n".join(entry))


def append_history(stats: dict) -> None:
    ensure_log(HISTORY_FILE, "# RAG eval history\n\n")
    lines = [
        f"## {stats['timestamp']}",
        f"- files sampled: {len(stats['files'])} ({stats['recent_count']} recent / {stats['random_count']} random)",
        f"- proposals received: {stats['proposals_total']}",
        f"  accepted: {stats['accepted']} "
        f"(reject: {stats['rejected_syntactic']} syntactic, "
        f"{stats['rejected_retrieval']} retrieval miss, "
        f"{stats['rejected_judge']} judge WRONG/UNCLEAR"
        + (f", {stats['judge_unavailable']} judge unavailable" if stats.get("judge_unavailable") else "")
        + ")",
        f"- revisit: {stats['revisit_checked']} checked, "
        f"{stats['revisit_strikes']} new strikes, {stats['revisit_retired']} retired",
    ]
    if stats.get("gaps_total"):
        lines.append(
            f"- gaps: {stats['gaps_total']} checked, "
            f"{stats['gaps_pruned']} pruned, {stats['gaps_kept']} kept")
    if stats.get("rejected_syntactic_reasons"):
        breakdown = ", ".join(
            f"{n} {r}" for r, n in sorted(
                stats["rejected_syntactic_reasons"].items(), key=lambda x: -x[1]))
        lines.append(f"  syntactic breakdown: {breakdown}")
    if "eval_total" in stats:
        pct = (stats["eval_passed"] * 100 // stats["eval_total"]) if stats["eval_total"] else 0
        lines.append(f"- eval: {stats['eval_passed']}/{stats['eval_total']} passing ({pct}%)"
                     + (f", {stats['eval_skipped']} skipped" if stats.get("eval_skipped") else ""))
    lines.append(f"- api cost: {stats['chat_calls']} chat + {stats['embed_calls']} embed")
    lines.append("")
    with HISTORY_FILE.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


# ----------------------------------------------------------------------------
# Main pipeline
# ----------------------------------------------------------------------------

def run_collection(args: argparse.Namespace, collection: str, eval_file_arg: str | None) -> int:
    """Run one full improve pass for a single collection.

    Sets the per-collection module globals (lockfile, repo root, eval file,
    excludes) then executes the propose → validate → judge → revisit → eval
    pipeline. Returns a process-style exit code; the --all loop OR's these.
    """
    global _EXCLUDES, EVAL_FILE, CURRENT_REPO_ROOT, LOCKFILE
    # Reset repo root each pass — under --all we run several collections in one
    # process, so don't let the previous collection's root leak into this one.
    CURRENT_REPO_ROOT = DOTFILES_ROOT
    # Per-collection lockfile so collections never block each other and a stuck
    # run only wedges its own collection, not the whole fleet.
    LOCKFILE = Path(f"/tmp/rag-improve.{collection}.lock")

    lock = acquire_lock()
    if lock is None:
        print(f"rag-improve: another run for '{collection}' in progress — exiting", file=sys.stderr)
        return 0

    # Resolve the eval file: explicit --eval-file wins, else derive from name.
    EVAL_FILE = (Path(eval_file_arg).expanduser().resolve()
                 if eval_file_arg else default_eval_file_for(collection))
    print(f"rag-improve: collection '{collection}' eval file {EVAL_FILE}", file=sys.stderr)

    root, _EXCLUDES = load_collection_config(collection)
    if root is not None:
        CURRENT_REPO_ROOT = root
        print(f"rag-improve: collection '{collection}' rooted at {CURRENT_REPO_ROOT}", file=sys.stderr)
    # NB: --use-claude-cli budget is configured once in main() (global across an
    # --all run), so it is intentionally not (re)set here per collection.

    try:
        today = datetime.date.today().isoformat()
        now_iso = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

        # --- file pools
        recent = [] if args.no_git else get_recent_files()
        indexed = get_indexed_files(collection)
        if not indexed:
            print(f"rag-improve: collection '{collection}' is empty", file=sys.stderr)
            return 1

        chosen = sample_files(recent, indexed, args.files_per_run, today)
        if not chosen:
            print("rag-improve: nothing to sample", file=sys.stderr)
            return 0

        recent_set = set(recent)
        stats = {
            "timestamp": now_iso,
            "files": [str(p.relative_to(CURRENT_REPO_ROOT)) if p.is_relative_to(CURRENT_REPO_ROOT) else str(p) for p in chosen],
            "recent_count": sum(1 for p in chosen if p in recent_set),
            "random_count": sum(1 for p in chosen if p not in recent_set),
            "proposals_total": 0,
            "accepted": 0,
            "rejected_syntactic": 0,
            "rejected_syntactic_reasons": {},  # reason -> count
            "rejected_retrieval": 0,
            "rejected_judge": 0,
            "judge_unavailable": 0,
            "chat_calls": 0,
            "embed_calls": 0,
            "revisit_checked": 0,
            "revisit_strikes": 0,
            "revisit_retired": 0,
            "gaps_total": 0,
            "gaps_pruned": 0,
            "gaps_kept": 0,
        }

        # --- load eval
        eval_data = json.loads(EVAL_FILE.read_text(encoding="utf-8"))
        existing_hashes = {hashlib.sha1(_norm_q(c["q"]).encode()).hexdigest() for c in eval_data["cases"]}

        accepted_cases: list[dict] = []

        for primary in chosen:
            print(f"→ {primary.name}", file=sys.stderr)
            pack, pack_lower = build_context_pack(primary, collection)
            stats["embed_calls"] += 1  # semantic neighbours

            prompt = PROPOSE_PROMPT_TMPL.format(pack=pack, n=args.cases_per_file)
            resp = chat(prompt, model=args.chat_model, max_tokens=1500)
            stats["chat_calls"] += 1
            proposals = parse_proposals(resp or "")
            stats["proposals_total"] += len(proposals)

            for p in proposals:
                ok, reason = validate_proposal(p, pack_lower, primary.name, existing_hashes)
                if not ok:
                    stats["rejected_syntactic"] += 1
                    # Bucket the reason so we can see if rejections are dominated
                    # by one cause (e.g. "duplicate question" → proposer keeps
                    # repeating itself once the corpus grows large).
                    bucket = reason.split("(")[0].strip() or reason
                    stats["rejected_syntactic_reasons"][bucket] = \
                        stats["rejected_syntactic_reasons"].get(bucket, 0) + 1
                    if args.dry_run:
                        print(f"  syntactic reject: {reason}  ({p['q'][:60]})", file=sys.stderr)
                    continue

                status, hits, r_reason = rag_eval.run_case(
                    {"q": p["q"], "must_contain": p["must_contain"]},
                    collection, args.top_k,
                )
                stats["embed_calls"] += 1

                if status == "skip":
                    continue
                if status == "fail":
                    stats["rejected_retrieval"] += 1
                    stats["embed_calls"] += 0  # retrieval already counted
                    if not args.dry_run:
                        append_gap(primary, p, hits, f"retrieval: {r_reason}", collection)
                    else:
                        print(f"  retrieval miss: {p['q'][:60]}", file=sys.stderr)
                    continue

                verdict, j_reason = judge(p["q"], hits, args.judge_model)
                stats["chat_calls"] += 1

                if verdict != "OK":
                    # Judge upstream failure is not a real gap — skip logging.
                    # Both the proposer and the judge can hallucinate, so we
                    # only record verdicts that came back from a live judge.
                    if j_reason == "(judge unavailable)":
                        stats["judge_unavailable"] += 1
                        if args.dry_run:
                            print(f"  judge unavailable, skipping: {p['q'][:60]}", file=sys.stderr)
                        continue
                    stats["rejected_judge"] += 1
                    if not args.dry_run:
                        append_gap(primary, p, hits, f"judge {verdict}: {j_reason}", collection)
                    else:
                        print(f"  judge {verdict}: {j_reason}  ({p['q'][:60]})", file=sys.stderr)
                    continue

                # Accept
                origin = str(primary.relative_to(CURRENT_REPO_ROOT)) if primary.is_relative_to(CURRENT_REPO_ROOT) else str(primary)
                new_case = {
                    "q": p["q"],
                    "must_contain": p["must_contain"],
                    "auto": True,
                    "origin": origin,
                    "added": today,
                    "strikes": 0,
                }
                accepted_cases.append(new_case)
                existing_hashes.add(hashlib.sha1(_norm_q(p["q"]).encode()).hexdigest())
                stats["accepted"] += 1
                if args.dry_run:
                    print(f"  ACCEPT: {p['q'][:60]} → {p['must_contain']}", file=sys.stderr)

        # --- commit to eval
        if accepted_cases and not args.dry_run:
            eval_data["cases"].extend(accepted_cases)

        # --- revisit
        if not args.no_revisit:
            rs = revisit_auto_cases(
                eval_data, collection,
                eval_data.get("top_k", args.top_k),
                args.revisit_sample, today,
            )
            stats["revisit_checked"] = rs["checked"]
            stats["revisit_strikes"] = rs["strikes_added"]
            stats["revisit_retired"] = rs["retired"]
            stats["embed_calls"] += rs["checked"]
            if not args.dry_run:
                for rc in rs["retired_cases"]:
                    append_retired(rc)

        # --- save eval atomically (if any change)
        if not args.dry_run and (accepted_cases or stats["revisit_retired"] or stats["revisit_strikes"]):
            save_eval_atomic(eval_data)

        # --- prune gap log: drop entries where retrieval now surfaces `expect`.
        # Operates only on the per-collection file (gaps/<collection>.md), not
        # the legacy aggregate — use `rag prune-gaps --legacy` for that on demand.
        if not args.no_prune_gaps:
            gaps_path = gaps_file_for(collection)
            if gaps_path.exists():
                top_k_prune = eval_data.get("top_k", args.top_k)
                ps = rag_prune_gaps.prune_file(
                    gaps_path, collection, top_k_prune, dry_run=args.dry_run)
                stats["gaps_total"] = ps["total"]
                stats["gaps_pruned"] = ps["closed"]
                stats["gaps_kept"] = ps["open"]
                stats["embed_calls"] += ps["total"]

        # --- full eval sweep
        if not args.no_final_eval:
            passed = failed = skipped = 0
            top_k = eval_data.get("top_k", args.top_k)
            coll = eval_data.get("collection", collection)
            for c in eval_data["cases"]:
                status, _, _ = rag_eval.run_case(c, coll, top_k)
                stats["embed_calls"] += 1
                if status == "pass":
                    passed += 1
                elif status == "fail":
                    failed += 1
                elif status == "skip":
                    skipped += 1
            stats["eval_passed"] = passed
            stats["eval_failed"] = failed
            stats["eval_skipped"] = skipped
            stats["eval_total"] = passed + failed + skipped

        # --- history
        if not args.dry_run:
            append_history(stats)

        # --- summary to stdout
        summary = (
            f"rag-improve[{collection}]: accepted {stats['accepted']}/{stats['proposals_total']}, "
            f"gaps: {stats['rejected_retrieval'] + stats['rejected_judge']}, "
            f"retired: {stats['revisit_retired']}"
        )
        if "eval_total" in stats:
            summary += f"  |  eval: {stats['eval_passed']}/{stats['eval_total']}"
        print(summary)
        return 0

    finally:
        if lock:
            fcntl.flock(lock, fcntl.LOCK_UN)
            lock.close()


def main() -> int:
    args = parse_args()

    if args.use_claude_cli:
        # Set the budget cap once for the whole process (shared across all
        # collections in an --all run, so the spend ceiling is global).
        global _CLAUDE_CLI_BUDGET_USD
        _CLAUDE_CLI_BUDGET_USD = float(args.claude_cli_budget_usd)
        print(f"rag-improve: routing chat() through `claude` CLI, budget "
              f"${_CLAUDE_CLI_BUDGET_USD:.2f}", file=sys.stderr)

    if not args.all:
        # Single-collection mode (default). No args -> dotfiles + rag.eval.json,
        # exactly as before, so existing callers and cron stay backward compatible.
        return run_collection(args, args.collection, args.eval_file)

    # --all: rotate through declared collections so we never hammer all of them
    # in one invocation. Each hourly run advances the cursor by --rotate.
    collections = discover_collections()
    if not collections:
        print("rag-improve: --all found no collections in rag.conf / rag.private.conf",
              file=sys.stderr)
        return 1
    picked, next_cursor = pick_rotation(collections, args.rotate)
    print(f"rag-improve: --all rotating {picked} "
          f"(of {len(collections)} declared; cursor -> {next_cursor})", file=sys.stderr)

    rc = 0
    for coll in picked:
        # --eval-file is meaningless across multiple collections — always derive.
        rc |= run_collection(args, coll, None)
    if not args.dry_run:
        # Persist the cursor only on a real run; dry-runs must not advance the
        # fleet, so they can be repeated freely while developing.
        _write_rotation_cursor(next_cursor)
    return rc


if __name__ == "__main__":
    sys.exit(main())
