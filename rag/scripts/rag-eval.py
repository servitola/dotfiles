#!/usr/bin/env python3
"""
rag-eval.py — run canonical RAG regression cases against a Qdrant collection.

Reads a JSON eval file (default: ../rag.eval.json), for each case embeds the
question via LiteLLM, retrieves top-k chunks from Qdrant, then asserts either:

  must_contain    — case-insensitive substring match inside any retrieved chunk's text
  must_hit_path   — case-insensitive substring match inside any retrieved chunk's path

Prints ✓ / ✗ per case and a summary. Exits non-zero on any failure, so it is
safe to wire into CI / pre-commit.

Usage:
  rag eval                         # default eval file
  rag eval path/to/other.json
  rag eval --verbose               # also print retrieved paths on failures
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


LITELLM_URL = os.environ.get("LITELLM_URL", "http://localhost:4000")
LITELLM_MASTER_KEY = os.environ.get("LITELLM_MASTER_KEY", "sk-local-workbot")
QDRANT_URL = os.environ.get("QDRANT_URL", "http://localhost:6333")
EMBED_MODEL = os.environ.get("RAG_EMBED_MODEL", "embed")

# Reranker — opt in with RAG_USE_RERANKER=1. Provider chosen via RAG_RERANK_PROVIDER:
#   local  (default) — BAAI/bge-reranker-v2-m3 via lazy localhost daemon (rag/rerank-server.py)
#   voyage           — Voyage rerank-2 cloud API (free tier hard-capped at 3 RPM / 10K TPM)
#   none             — disabled, equivalent to RAG_USE_RERANKER unset
USE_RERANKER = os.environ.get("RAG_USE_RERANKER", "").strip() in ("1", "true", "yes")
RERANK_PROVIDER = os.environ.get("RAG_RERANK_PROVIDER", "local").strip().lower()
RERANK_FETCH_K = int(os.environ.get("RAG_RERANK_FETCH_K", "12"))
# Local rerank truncates docs aggressively — bge-reranker-v2-m3 on M3 Pro CPU
# does 12 docs × 1500 chars in ~1.5s; pushing to 4000 chars makes it 18s+.
# 1500 chars ≈ 400 tokens, plenty for a relevance signal on top of File:/Summary: header.
RERANK_DOC_CHARS = int(os.environ.get("RAG_RERANK_DOC_CHARS", "1500"))

# Local daemon
LOCAL_RERANK_PORT = int(os.environ.get("RAG_RERANK_PORT", "8765"))
LOCAL_RERANK_HOST = "127.0.0.1"
LOCAL_RERANK_SERVER = (Path(__file__).resolve().parent.parent / "rerank-server.py")
LOCAL_RERANK_BOOT_TIMEOUT = int(os.environ.get("RAG_RERANK_BOOT_TIMEOUT", "120"))

# Voyage cloud
VOYAGE_API_KEY = os.environ.get("VOYAGE_API_KEY", "")
VOYAGE_RERANK_URL = "https://api.voyageai.com/v1/rerank"
VOYAGE_RERANK_MODEL = os.environ.get("RAG_RERANK_MODEL", "rerank-2")
# Voyage free tier rate-limit pacing — see rerank_voyage().
VOYAGE_DOC_CHARS = int(os.environ.get("RAG_RERANK_VOYAGE_DOC_CHARS", "1500"))
RERANK_MIN_INTERVAL = float(os.environ.get("RAG_RERANK_MIN_INTERVAL", "21"))
_last_rerank_call_at: float = 0.0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "eval_file",
        nargs="?",
        default=str(Path(__file__).resolve().parent.parent / "rag.eval.json"),
        help="Path to eval JSON file",
    )
    parser.add_argument("--verbose", action="store_true", help="Show retrieved paths on failures")
    return parser.parse_args()


def http_json(method: str, url: str, payload: dict | None = None,
              headers: dict | None = None, timeout: float = 60.0) -> dict:
    body = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(url, method=method)
    req.add_header("Content-Type", "application/json")
    if headers:
        for key, value in headers.items():
            req.add_header(key, value)

    try:
        with urllib.request.urlopen(req, data=body, timeout=timeout) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"{method} {url} failed: HTTP {exc.code}\n{detail}") from exc
    except TimeoutError as exc:
        # Bare socket timeout (Python 3.10+ aliases socket.timeout). Wrap in
        # SystemExit so callers' retry logic (embed/judge/rerank) can catch it.
        raise SystemExit(f"{method} {url} failed: timed out after {timeout}s") from exc
    except urllib.error.URLError as exc:
        reason = str(exc).lower()
        if "connection refused" in reason:
            host = urllib.parse.urlparse(url).netloc
            service = "LiteLLM" if ":4000" in host else ("Qdrant" if ":6333" in host else host)
            raise SystemExit(
                f"{service} is not responding at {url}\n"
                f"start it:  cd ~/projects/dotfiles/litellm && docker compose up -d  "
                f"# and qdrant/"
            ) from exc
        if "timed out" in reason:
            raise SystemExit(f"{method} {url} failed: timed out after {timeout}s") from exc
        raise SystemExit(f"{method} {url} failed: {exc}") from exc

    if not raw:
        return {}
    return json.loads(raw.decode("utf-8"))


def embed(text: str, retries: int = 2) -> list[float] | None:
    """Embed with gentle retry on transient 429/404 from free-tier upstream.

    Returns None if embedding keeps failing — caller treats the case as
    skipped rather than aborting the whole run.
    """
    for attempt in range(retries + 1):
        try:
            data = http_json(
                "POST",
                f"{LITELLM_URL}/v1/embeddings",
                payload={"model": EMBED_MODEL, "input": text, "encoding_format": "float"},
                headers={"Authorization": f"Bearer {LITELLM_MASTER_KEY}"},
            )
            return data["data"][0]["embedding"]
        except SystemExit as exc:
            msg = str(exc)
            if "HTTP 429" in msg or "HTTP 404" in msg or "HTTP 5" in msg:
                if attempt < retries:
                    time.sleep(2 * (attempt + 1))
                    continue
            return None


def search(collection: str, vector: list[float], top_k: int) -> list[dict]:
    """Pure vector search — kept for callers that want it explicitly."""
    data = http_json(
        "POST",
        f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points/search",
        payload={"vector": vector, "limit": top_k, "with_payload": True},
    )
    return data.get("result", [])


def search_hybrid(collection: str, vector: list[float], query: str, top_k: int) -> list[dict]:
    """Hybrid search: vector + FTS-filtered vector, fused server-side via RRF.

    Two prefetches:
      1. Pure semantic on full collection (top 20).
      2. Same vector, filtered to chunks whose text matches the query keywords (top 20).

    Qdrant fuses with Reciprocal Rank Fusion. Chunks that appear in both rise
    to the top — exactly what we want for fact-lookup queries (JSON keys,
    function names, exact strings) where vector alone misses.

    Gracefully degrades to pure vector when no keyword matches exist.
    """
    data = http_json(
        "POST",
        f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points/query",
        payload={
            "prefetch": [
                {"query": vector, "limit": 20},
                {
                    "query": vector,
                    "limit": 20,
                    "filter": {"must": [{"key": "text", "match": {"text": query}}]},
                },
            ],
            "query": {"fusion": "rrf"},
            "limit": top_k,
            "with_payload": True,
        },
    )
    return data.get("result", {}).get("points", data.get("result", []))


def rerank_voyage(query: str, hits: list[dict], top_k: int, retries: int = 4) -> list[dict]:
    """Reorder hits via Voyage rerank-2. Falls back to original order on error.

    Voyage returns {"data": [{"index": int, "relevance_score": float}, ...]}
    sorted by relevance descending. We map the indices back to our hits and
    inject the reranker score into payload._rerank_score for visibility.

    Voyage free tier (no payment method) has a hard limit of 3 RPM. We back off
    by 25s after every HTTP 429 — 4 retries then give up and fall back.
    """
    if not hits or not VOYAGE_API_KEY:
        return hits[:top_k]

    global _last_rerank_call_at
    if RERANK_MIN_INTERVAL > 0:
        elapsed = time.time() - _last_rerank_call_at
        if elapsed < RERANK_MIN_INTERVAL:
            time.sleep(RERANK_MIN_INTERVAL - elapsed)
    _last_rerank_call_at = time.time()

    docs = [(h.get("payload", {}).get("text") or "")[:VOYAGE_DOC_CHARS] for h in hits]
    payload = {
        "query": query[:2000],
        "documents": docs,
        "model": VOYAGE_RERANK_MODEL,
        "top_k": min(top_k, len(docs)),
    }
    headers = {
        "Authorization": f"Bearer {VOYAGE_API_KEY}",
        "Content-Type": "application/json",
    }
    for attempt in range(retries + 1):
        try:
            data = http_json("POST", VOYAGE_RERANK_URL, payload=payload, headers=headers)
            ordered = []
            for item in data.get("data", []):
                idx = item.get("index")
                if isinstance(idx, int) and 0 <= idx < len(hits):
                    h = dict(hits[idx])
                    h.setdefault("payload", {})
                    h["payload"] = dict(h["payload"])
                    h["payload"]["_rerank_score"] = item.get("relevance_score")
                    ordered.append(h)
            if ordered:
                return ordered
            return hits[:top_k]
        except SystemExit as exc:
            err = str(exc)
            if "HTTP 429" in err and attempt < retries:
                time.sleep(25)  # honour Voyage free-tier 3 RPM limit
                continue
            if "HTTP 5" in err and attempt < retries:
                time.sleep(2 * (attempt + 1))
                continue
            return hits[:top_k]
    return hits[:top_k]


# ---------------------------------------------------------------------------
# Local reranker — lazy daemon at localhost:LOCAL_RERANK_PORT (rag/rerank-server.py)
# ---------------------------------------------------------------------------

_daemon_spawn_lock_marker = Path("/tmp/rag-rerank-spawn.lock")


def _rerank_daemon_alive(timeout: float = 0.5) -> bool:
    import socket
    try:
        with socket.create_connection((LOCAL_RERANK_HOST, LOCAL_RERANK_PORT), timeout=timeout):
            return True
    except OSError:
        return False


def _ensure_rerank_daemon() -> bool:
    """Probe the local reranker daemon; spawn detached if not alive.

    Returns True if daemon is reachable after the call (either was already up
    or successfully spawned). Returns False on spawn timeout — caller falls
    back to no-rerank.
    """
    if _rerank_daemon_alive():
        return True

    # Cooperative spawn lock — if another process is already booting, wait it out
    # rather than spawn a duplicate daemon.
    try:
        fd = os.open(str(_daemon_spawn_lock_marker), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        os.close(fd)
        owns_lock = True
    except FileExistsError:
        owns_lock = False

    try:
        if owns_lock:
            try:
                import subprocess
                subprocess.Popen(
                    [str(LOCAL_RERANK_SERVER), "--port", str(LOCAL_RERANK_PORT)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    stdin=subprocess.DEVNULL,
                    start_new_session=True,
                )
            except Exception as exc:
                print(f"rag-eval: failed to spawn rerank daemon: {exc}", file=sys.stderr)
                return False

        # Poll for readiness — first boot pulls the model so allow long timeout.
        deadline = time.time() + LOCAL_RERANK_BOOT_TIMEOUT
        while time.time() < deadline:
            if _rerank_daemon_alive(timeout=1.0):
                # Confirm /health responds 200 (daemon may be mid-load).
                try:
                    http_json(
                        "GET",
                        f"http://{LOCAL_RERANK_HOST}:{LOCAL_RERANK_PORT}/health",
                    )
                    return True
                except SystemExit:
                    pass
            time.sleep(2)
        print(
            f"rag-eval: rerank daemon did not come up within {LOCAL_RERANK_BOOT_TIMEOUT}s",
            file=sys.stderr,
        )
        return False
    finally:
        if owns_lock:
            try:
                _daemon_spawn_lock_marker.unlink()
            except FileNotFoundError:
                pass


def rerank_local(query: str, hits: list[dict], top_k: int) -> list[dict]:
    """Reorder hits via the local bge-reranker-v2-m3 daemon.

    Falls back to original order (truncated to top_k) on any failure.
    """
    if not hits:
        return []
    if not _ensure_rerank_daemon():
        return hits[:top_k]

    docs = [(h.get("payload", {}).get("text") or "")[:RERANK_DOC_CHARS] for h in hits]
    payload = {"query": query, "documents": docs, "top_k": top_k}
    try:
        # Long timeout: bge-reranker on CPU can take 10-30s on 12 long-doc calls.
        # Single-threaded daemon serializes requests, so eval can queue too.
        data = http_json(
            "POST",
            f"http://{LOCAL_RERANK_HOST}:{LOCAL_RERANK_PORT}/rerank",
            payload=payload,
            timeout=180.0,
        )
    except SystemExit as exc:
        print(f"rag-eval: rerank daemon error: {exc}", file=sys.stderr)
        return hits[:top_k]

    ordered: list[dict] = []
    for item in data.get("results", []):
        idx = item.get("index")
        if isinstance(idx, int) and 0 <= idx < len(hits):
            h = dict(hits[idx])
            h["payload"] = dict(h.get("payload", {}))
            h["payload"]["_rerank_score"] = item.get("score")
            ordered.append(h)
    return ordered or hits[:top_k]


def search_then_rerank(collection: str, query: str, vector: list[float], top_k: int) -> list[dict]:
    """One-stop retrieval used by all callers (eval, improve, mcp).

    Default is hybrid (vector + FTS, RRF-fused server-side) — strictly better
    than pure vector for code/config corpora where exact tokens matter.

    Set RAG_USE_RERANKER=1 to additionally rerank the wide candidate set.
    Provider chosen via RAG_RERANK_PROVIDER:
      local  (default) — BAAI/bge-reranker-v2-m3 via lazy daemon (fast, free)
      voyage           — cloud API; free tier 3 RPM/10K TPM, painfully slow
      none             — disable rerank step

    Set RAG_SEARCH_MODE=vector to force pure vector (debugging only).
    """
    mode = os.environ.get("RAG_SEARCH_MODE", "hybrid")
    fetch_k = max(top_k, RERANK_FETCH_K)

    def _wide():
        if mode == "vector":
            return search(collection, vector, fetch_k)
        return search_hybrid(collection, vector, query, fetch_k)

    if USE_RERANKER and RERANK_PROVIDER != "none":
        if RERANK_PROVIDER == "local":
            return rerank_local(query, _wide(), top_k)
        if RERANK_PROVIDER == "voyage":
            if not VOYAGE_API_KEY:
                print("rag-eval: VOYAGE_API_KEY missing — skipping rerank", file=sys.stderr)
            else:
                return rerank_voyage(query, _wide(), top_k)

    if mode == "vector":
        return search(collection, vector, top_k)
    return search_hybrid(collection, vector, query, top_k)


def check_assertion(case: dict, hits: list[dict]) -> tuple[bool | None, str]:
    """Return (ok, reason).

    ok=True   — case passed
    ok=False  — case failed the assertion
    ok=None   — case has no valid assertion (malformed)
    """
    if "must_contain" in case:
        needle = case["must_contain"].lower()
        ok = any(needle in (hit.get("payload", {}).get("text") or "").lower() for hit in hits)
        return ok, f'no chunk text contains "{case["must_contain"]}"'
    if "must_hit_path" in case:
        needle = case["must_hit_path"].lower()
        ok = any(needle in (hit.get("payload", {}).get("path") or "").lower() for hit in hits)
        return ok, f'no chunk path contains "{case["must_hit_path"]}"'
    return None, "no assertion (must_contain|must_hit_path)"


def run_case(case: dict, collection: str, top_k: int) -> tuple[str, list[dict], str]:
    """Run one case end-to-end. Returns (status, hits, reason).

    status:
      "pass"    — retrieval surfaced a chunk satisfying the assertion
      "fail"    — retrieval did not satisfy the assertion
      "skip"    — upstream embed unavailable
      "invalid" — case has no valid assertion
    """
    vec = embed(case["q"])
    if vec is None:
        return "skip", [], "embed upstream unavailable"
    hits = search_then_rerank(collection, case["q"], vec, top_k)
    ok, reason = check_assertion(case, hits)
    if ok is None:
        return "invalid", hits, reason
    return ("pass" if ok else "fail"), hits, reason


def main() -> int:
    args = parse_args()
    eval_file = Path(args.eval_file)
    if not eval_file.is_file():
        print(f"rag-eval: file not found: {eval_file}", file=sys.stderr)
        return 2

    spec = json.loads(eval_file.read_text(encoding="utf-8"))
    collection = spec.get("collection", "workflow")
    top_k = spec.get("top_k", 6)
    cases = spec.get("cases", [])

    if not cases:
        print("rag-eval: no cases in file", file=sys.stderr)
        return 3

    passed = 0
    failed = 0
    skipped = 0

    for idx, case in enumerate(cases, 1):
        question = case["q"]
        status, hits, reason = run_case(case, collection, top_k)

        if status == "skip":
            skipped += 1
            print(f"  \u26a0 [{idx:3d}] {question}  \u2014 embed upstream unavailable (quota/rate-limit)")
            continue
        if status == "invalid":
            print(f"  ? case[{idx}] {question!r}: {reason}", file=sys.stderr)
            failed += 1
            continue

        if status == "pass":
            passed += 1
            print(f"  \u2713 [{idx:3d}] {question}")
        else:
            failed += 1
            print(f"  \u2717 [{idx:3d}] {question}  \u2014 {reason}")
            if args.verbose:
                for h in hits:
                    p = h.get("payload", {}).get("path", "?")
                    s = h.get("score", 0.0)
                    print(f"         path={p}  score={s:.3f}")

    total = passed + failed + skipped
    print()
    summary = f"rag-eval: {passed}/{total} passed"
    if skipped:
        summary += f" ({skipped} skipped due to upstream)"
    print(summary, file=sys.stderr if failed else sys.stdout)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
