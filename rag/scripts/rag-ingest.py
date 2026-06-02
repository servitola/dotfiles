#!/usr/bin/env python3
"""
rag-ingest.py — index local text files into Qdrant via LiteLLM embeddings.

Smart incremental mode (--sync, used by `rag refresh`):
  1. Load content hashes from Qdrant for all indexed files
  2. Skip files whose content hasn't changed (same SHA-256)
  3. Re-ingest changed/new files (with LLM summaries if --llm-summary)
  4. Delete orphan points (files removed from disk)
  → Minimal API calls, always-clean collection state.

Examples:
  ./scripts/rag-ingest.py ~/projects/dotfiles/README.md
  ./scripts/rag-ingest.py --collection dotfiles --sync --llm-summary ~/projects/dotfiles
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import textwrap
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Iterable


LITELLM_URL = os.environ.get("LITELLM_URL", "http://localhost:4000")
LITELLM_MASTER_KEY = os.environ.get("LITELLM_MASTER_KEY", "sk-local-workbot")
QDRANT_URL = os.environ.get("QDRANT_URL", "http://localhost:6333")
EMBED_MODEL = os.environ.get("RAG_EMBED_MODEL", "embed")
DEFAULT_COLLECTION = os.environ.get("RAG_COLLECTION", "workflow")

DEFAULT_EXTENSIONS = {
    ".md",
    ".txt",
    ".rst",
    ".org",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".ini",
    ".conf",
    ".sh",
    ".zsh",
    ".bash",
    ".lua",
    ".py",
    ".js",
    ".ts",
    ".tsx",
    ".jsx",
    ".css",
    ".html",
    ".sql",
    ".keylayout",
    ".plist",
}

# Path segments always skipped during recursion — these are never useful for
# RAG and frequently contain noise that would drown real content. Matched by
# exact segment name (not substring), so e.g. ".git" is skipped but "git"
# (legitimate config dir) is not.
ALWAYS_SKIP_SEGMENTS = {
    # VCS / editor
    ".git",
    ".idea",
    # Python
    "__pycache__",
    ".ruff_cache",
    ".venv",
    "venv",
    ".pytest_cache",
    ".mypy_cache",
    ".tox",
    # Node / JS
    "node_modules",
    ".next",
    ".nuxt",
    ".svelte-kit",
    ".turbo",
    ".parcel-cache",
    ".nyc_output",
    # Rust
    "target",
    # Go / PHP
    "vendor",
    # iOS / Xcode
    "DerivedData",
    "Pods",
    ".swiftpm",
    # .NET / JVM
    "obj",
    ".gradle",
    # Infra
    ".terraform",
    # Generic build/cache/output
    ".cache",
    "dist",
    "build",
    "coverage",
    "out",
}

# Filename patterns always skipped — lock files, minified bundles, generated
# manifests that match an allowed extension but carry no useful signal.
SKIP_FILENAMES = {
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
    "Cargo.lock",
    "poetry.lock",
    "Pipfile.lock",
    "composer.lock",
    "Gemfile.lock",
    "uv.lock",
    "bun.lockb",
}

# Suffixes (full match against name.lower()) — for *.min.js, *.min.css, etc.
SKIP_NAME_SUFFIXES = (
    ".min.js",
    ".min.css",
    ".min.html",
    ".bundle.js",
    ".bundle.css",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", help="Files or directories to index")
    parser.add_argument("--collection", default=DEFAULT_COLLECTION)
    # Verified pair: 2400/300 with hybrid search (RAG_SEARCH_MODE=hybrid in
    # rag-eval) achieves 99.66% pass rate on the dotfiles eval. Bumping chars
    # gives reranker / judge more context per chunk; hybrid search handles
    # exact-token recall that bigger chunks otherwise dilute.
    parser.add_argument("--chunk-size", type=int, default=2400, help="Target characters per chunk")
    parser.add_argument("--chunk-overlap", type=int, default=300, help="Overlap characters between chunks")
    parser.add_argument("--batch-size", type=int, default=16, help="Embedding batch size")
    parser.add_argument(
        "--extensions",
        default=",".join(sorted(ext.lstrip(".") for ext in DEFAULT_EXTENSIONS)),
        help="Comma-separated allowed file extensions without dots",
    )
    parser.add_argument("--source", default=None, help="Source label stored in payload")
    parser.add_argument("--max-files", type=int, default=0, help="Stop after indexing N files (0 = no limit)")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="Substring to skip in file paths (repeatable). "
             "E.g. --exclude /annepro2/ --exclude /ufc-stats/",
    )
    parser.add_argument(
        "--llm-summary",
        action="store_true",
        default=False,
        help="Generate file summaries via LLM instead of heuristic extraction. "
             "Uses RAG_SUMMARY_MODEL (default: gpt) via LiteLLM.",
    )
    parser.add_argument(
        "--summary-model",
        default=os.environ.get("RAG_SUMMARY_MODEL", "gpt"),
        help="LiteLLM model alias for summary generation (default: gpt)",
    )
    parser.add_argument(
        "--sync",
        action="store_true",
        default=False,
        help="Smart incremental sync: skip unchanged files (by content hash), "
             "delete orphan points for files no longer on disk. "
             "Used by `rag refresh`.",
    )
    return parser.parse_args()


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

# HTTP status codes worth retrying. 5xx = server errors, 429 = rate limit,
# 408 = request timeout. 400 is also retried because LiteLLM wraps transient
# upstream OpenAI errors as 400 (e.g. `Received Model Group=embed / Available
# Model Group Fallbacks=None`).
_RETRYABLE_HTTP = {400, 408, 429, 500, 502, 503, 504}


def http_json(
    method: str,
    url: str,
    payload: dict | None = None,
    headers: dict | None = None,
    retries: int = 0,
    retry_backoff: float = 2.0,
) -> dict:
    body = None if payload is None else json.dumps(payload).encode()
    last_exc: Exception | None = None
    last_detail: str = ""
    for attempt in range(retries + 1):
        req = urllib.request.Request(url, method=method)
        req.add_header("Content-Type", "application/json")
        if headers:
            for key, value in headers.items():
                req.add_header(key, value)
        try:
            with urllib.request.urlopen(req, data=body, timeout=60) as resp:
                raw = resp.read()
            if not raw:
                return {}
            return json.loads(raw.decode("utf-8"))
        except urllib.error.HTTPError as exc:
            last_exc = exc
            last_detail = exc.read().decode("utf-8", errors="replace")
            if attempt < retries and exc.code in _RETRYABLE_HTTP:
                import time as _t
                delay = retry_backoff * (2 ** attempt)
                print(
                    f"{method} {url}: HTTP {exc.code}, retry {attempt + 1}/{retries} in {delay:.1f}s",
                    file=sys.stderr,
                )
                _t.sleep(delay)
                continue
            raise SystemExit(f"{method} {url} failed: HTTP {exc.code}\n{last_detail}") from exc
        except urllib.error.URLError as exc:
            last_exc = exc
            reason = str(exc).lower()
            unreachable = (
                "connection refused" in reason
                or "no route" in reason
                or "network is unreachable" in reason
            )
            if unreachable:
                host = urllib.parse.urlparse(url).netloc
                service = "LiteLLM" if ":4000" in host else ("Qdrant" if ":6333" in host else host)
                raise SystemExit(
                    f"{service} is not responding at {url}\n"
                    f"start it:  cd ~/projects/dotfiles/litellm && docker compose up -d  "
                    f"# and qdrant/"
                ) from exc
            if attempt < retries:
                import time as _t
                delay = retry_backoff * (2 ** attempt)
                print(
                    f"{method} {url}: {exc}, retry {attempt + 1}/{retries} in {delay:.1f}s",
                    file=sys.stderr,
                )
                _t.sleep(delay)
                continue
            raise SystemExit(f"{method} {url} failed: {exc}") from exc
    # Unreachable: loop either returns or raises.
    raise SystemExit(f"{method} {url} failed after {retries} retries: {last_exc}")


def http_json_safe(method: str, url: str, payload: dict | None = None, headers: dict | None = None) -> dict | None:
    """Like http_json but returns None on HTTP errors instead of exiting."""
    try:
        body = None if payload is None else json.dumps(payload).encode()
        req = urllib.request.Request(url, method=method)
        req.add_header("Content-Type", "application/json")
        if headers:
            for k, v in headers.items():
                req.add_header(k, v)
        with urllib.request.urlopen(req, data=body, timeout=30) as resp:
            raw = resp.read()
        return json.loads(raw.decode("utf-8")) if raw else {}
    except Exception:
        return None


# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------

def _is_filtered(path: Path, excludes: list[str]) -> bool:
    # Hard-coded segment skip (never useful for RAG).
    if ALWAYS_SKIP_SEGMENTS.intersection(path.parts):
        return True
    # Filename / suffix skip (lock files, minified bundles, etc).
    name_lower = path.name.lower()
    if path.name in SKIP_FILENAMES:
        return True
    if any(name_lower.endswith(suf) for suf in SKIP_NAME_SUFFIXES):
        return True
    # User-supplied substring excludes.
    if excludes:
        path_str = str(path)
        if any(ex in path_str for ex in excludes):
            return True
    return False


def iter_files(
    paths: list[str],
    allowed_extensions: set[str],
    max_files: int,
    excludes: list[str] | None = None,
) -> Iterable[Path]:
    excludes = excludes or []
    yielded = 0
    for raw in paths:
        path = Path(raw).expanduser().resolve()
        if path.is_file():
            if path.suffix.lower() in allowed_extensions and not _is_filtered(path, excludes):
                yield path
                yielded += 1
        elif path.is_dir():
            for child in sorted(path.rglob("*")):
                if not child.is_file():
                    continue
                if child.suffix.lower() not in allowed_extensions:
                    continue
                if _is_filtered(child, excludes):
                    continue
                yield child
                yielded += 1
                if max_files and yielded >= max_files:
                    return
        else:
            print(f"skip missing path: {path}", file=sys.stderr)

        if max_files and yielded >= max_files:
            return


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def content_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


# ---------------------------------------------------------------------------
# Summary extraction
# ---------------------------------------------------------------------------

def _repo_relative_path(path: Path) -> str:
    """Best-effort relative path from the nearest repo-ish ancestor."""
    for parent in [path] + list(path.parents):
        if (parent / ".git").exists() or (parent / ".claude").exists():
            try:
                return str(path.relative_to(parent))
            except ValueError:
                break
    parts = path.parts
    return "/".join(parts[-3:]) if len(parts) >= 3 else path.name


def _stem_or_parent(path: Path) -> str:
    generic = {"init", "index", "main", "mod", "__init__"}
    stem = path.stem
    if stem.lower() in generic:
        parent = path.parent.name
        return parent if parent else stem
    return stem


def _extract_summary(path: Path, text: str) -> str:
    """One-line summary for the file, used by embed as a topical anchor."""
    ext = path.suffix.lower()
    head = text[:4000]

    if ext == ".md":
        for line in head.splitlines():
            stripped = line.strip()
            if stripped.startswith("# ") and len(stripped) > 2:
                return stripped[2:].strip()
        return _stem_or_parent(path)

    if ext == ".json":
        try:
            obj = json.loads(text)
        except json.JSONDecodeError:
            return _stem_or_parent(path)
        if isinstance(obj, dict):
            desc = obj.get("description") or obj.get("title") or obj.get("name")
            if isinstance(desc, str) and desc.strip():
                return desc.strip()
            rules = obj.get("rules")
            if isinstance(rules, list) and rules and isinstance(rules[0], dict):
                d0 = rules[0].get("description")
                if isinstance(d0, str) and d0.strip():
                    return d0.strip()
        return _stem_or_parent(path)

    if ext in {".lua", ".py", ".sh", ".zsh", ".bash", ".js", ".ts", ".tsx", ".jsx"}:
        comment_prefixes = ("#", "--", "//", "/*", "*")
        skip_prefixes = ("#!", "#!/")
        lines: list[str] = []
        scanned = 0
        in_block = False
        for raw in head.splitlines():
            scanned += 1
            if scanned > 30:
                break
            stripped = raw.strip()
            if not stripped:
                if in_block:
                    break
                continue
            if stripped.startswith(skip_prefixes):
                continue
            if stripped.startswith(comment_prefixes):
                lines.append(stripped.lstrip("#-/* \t").strip())
                in_block = True
            elif in_block:
                break
        if lines:
            joined = " ".join(l for l in lines if l)
            return joined[:160] if joined else path.stem
        return _stem_or_parent(path)

    return _stem_or_parent(path)


def _llm_summary(path: Path, text: str, model: str) -> str:
    """Generate a one-line file summary via LLM. Falls back to heuristic on failure."""
    import time as _time

    head = text[:3000]
    rel = _repo_relative_path(path)
    prompt = (
        f"File: {rel}\n\n{head}\n\n"
        "Write a single-line summary (max 120 chars) describing what this file does or contains. "
        "Be specific — mention the tool/app name, purpose, key configs. "
        "No markdown, no quotes, just plain text."
    )
    for attempt in range(3):
        data = http_json_safe(
            "POST",
            f"{LITELLM_URL}/v1/chat/completions",
            payload={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 80,
                "temperature": 0.0,
            },
            headers={"Authorization": f"Bearer {LITELLM_MASTER_KEY}"},
        )
        if data and "choices" in data:
            answer = data["choices"][0]["message"]["content"].strip().strip('"\'')
            if answer and len(answer) > 5:
                return answer[:160]
            break
        # Rate limit or transient error — back off and retry.
        if attempt < 2:
            _time.sleep(5 * (attempt + 1))
    return _extract_summary(path, text)


def build_file_header(path: Path, text: str, llm_summary_model: str | None = None) -> str:
    rel = _repo_relative_path(path)
    if llm_summary_model:
        summary = _llm_summary(path, text, llm_summary_model)
    else:
        summary = _extract_summary(path, text)
    return f"File: {rel}\nSummary: {summary}\n\n"


# ---------------------------------------------------------------------------
# Chunking
# ---------------------------------------------------------------------------

def chunk_text(text: str, chunk_size: int, chunk_overlap: int) -> list[str]:
    text = text.strip()
    if not text:
        return []

    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    chunks: list[str] = []
    current = ""

    for para in paragraphs:
        para = para.strip()
        if len(para) > chunk_size:
            lines = textwrap.wrap(
                para,
                width=max(200, chunk_size - 50),
                break_long_words=False,
                break_on_hyphens=False,
            )
        else:
            lines = [para]

        for part in lines:
            candidate = f"{current}\n\n{part}".strip() if current else part
            if len(candidate) <= chunk_size:
                current = candidate
                continue

            if current:
                chunks.append(current)
            overlap = current[-chunk_overlap:] if current and chunk_overlap > 0 else ""
            current = f"{overlap}\n{part}".strip() if overlap else part

    if current:
        chunks.append(current)

    return chunks


# ---------------------------------------------------------------------------
# Qdrant operations
# ---------------------------------------------------------------------------

def embed_texts(texts: list[str]) -> list[list[float]]:
    # LiteLLM upstream (OpenAI, etc.) hiccups happen — retry transient errors.
    data = http_json(
        "POST",
        f"{LITELLM_URL}/v1/embeddings",
        payload={"model": EMBED_MODEL, "input": texts, "encoding_format": "float"},
        headers={"Authorization": f"Bearer {LITELLM_MASTER_KEY}"},
        retries=3,
    )
    return [item["embedding"] for item in data["data"]]


def ensure_collection(collection: str, vector_size: int) -> None:
    collections = http_json("GET", f"{QDRANT_URL}/collections")
    names = {item["name"] for item in collections.get("result", {}).get("collections", [])}
    if collection in names:
        return

    http_json(
        "PUT",
        f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}",
        payload={"vectors": {"size": vector_size, "distance": "Cosine"}},
    )


def ensure_text_index(collection: str) -> None:
    coll_url = f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}"
    info = http_json("GET", coll_url)
    schema = info.get("result", {}).get("payload_schema", {})
    if "text" in schema:
        return
    http_json(
        "PUT",
        f"{coll_url}/index",
        payload={
            "field_name": "text",
            "field_schema": {
                "type": "text",
                "tokenizer": "word",
                "min_token_len": 2,
                "lowercase": True,
            },
        },
    )


def make_point_id(path: Path, chunk_index: int) -> str:
    seed = f"{path}:{chunk_index}"
    digest = hashlib.sha1(seed.encode("utf-8")).hexdigest()
    return str(uuid.UUID(digest[:32]))


def upsert_points(collection: str, points: list[dict]) -> None:
    http_json(
        "PUT",
        f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points",
        payload={"points": points},
    )


def load_existing_hashes(collection: str) -> dict[str, str]:
    """Scroll through all points and return {path: content_hash}.

    For files with multiple chunks, every chunk stores the same content_hash,
    so we just take the first one we see per path.
    """
    coll_url = f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}"
    # Check if collection exists first.
    result = http_json_safe("GET", coll_url)
    if result is None or "result" not in result:
        return {}

    hashes: dict[str, str] = {}
    offset = None  # Qdrant scroll uses point ID as offset, None = start
    while True:
        body: dict = {
            "limit": 100,
            "with_payload": {"include": ["path", "content_hash"]},
            "with_vector": False,
        }
        if offset is not None:
            body["offset"] = offset
        data = http_json_safe("POST", f"{coll_url}/points/scroll", payload=body)
        if data is None:
            break
        points = data.get("result", {}).get("points", [])
        if not points:
            break
        for pt in points:
            p = pt.get("payload", {})
            path = p.get("path")
            h = p.get("content_hash")
            if path and h and path not in hashes:
                hashes[path] = h
        next_offset = data.get("result", {}).get("next_page_offset")
        if next_offset is None:
            break
        offset = next_offset
    return hashes


def delete_points_by_paths(collection: str, paths: set[str]) -> int:
    """Delete all points whose 'path' payload matches any of the given paths."""
    if not paths:
        return 0
    coll_url = f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points/delete"
    # Qdrant filter: match any of the given path values.
    http_json(
        "POST",
        coll_url,
        payload={
            "filter": {
                "must": [
                    {"key": "path", "match": {"any": list(paths)}}
                ]
            }
        },
    )
    return len(paths)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    args = parse_args()
    extensions = {"." + ext.strip().lstrip(".").lower() for ext in args.extensions.split(",") if ext.strip()}

    files = list(iter_files(args.paths, extensions, args.max_files, excludes=args.exclude))
    if not files:
        print("No matching files found.", file=sys.stderr)
        return 1

    # In sync mode, load existing content hashes to skip unchanged files.
    existing_hashes: dict[str, str] = {}
    if args.sync:
        existing_hashes = load_existing_hashes(args.collection)
        if existing_hashes:
            print(f"sync: {len(existing_hashes)} files already indexed, checking for changes...")

    llm_model = args.summary_model if args.llm_summary else None
    total_points = 0
    total_files = 0
    skipped_files = 0
    collection_ready = False
    current_paths: set[str] = set()  # all paths we see on disk (for orphan cleanup)

    for path in files:
        text = read_text(path)
        path_str = str(path)
        current_paths.add(path_str)
        h = content_hash(text)

        # Skip unchanged files in sync mode.
        if args.sync and existing_hashes.get(path_str) == h:
            skipped_files += 1
            continue

        chunks = chunk_text(text, args.chunk_size, args.chunk_overlap)
        if not chunks:
            continue

        header = build_file_header(path, text, llm_summary_model=llm_model)
        chunks = [header + chunk for chunk in chunks]

        embeddings: list[list[float]] = []
        for idx in range(0, len(chunks), args.batch_size):
            batch = chunks[idx : idx + args.batch_size]
            embeddings.extend(embed_texts(batch))

        if not collection_ready and embeddings:
            ensure_collection(args.collection, len(embeddings[0]))
            ensure_text_index(args.collection)
            collection_ready = True

        # In sync mode, delete old chunks for this file before upserting new
        # ones. This handles files that shrank (fewer chunks than before).
        if args.sync and path_str in existing_hashes:
            delete_points_by_paths(args.collection, {path_str})

        points = []
        rel_source = args.source or path.anchor or "local"
        for idx, (chunk, vector) in enumerate(zip(chunks, embeddings)):
            payload = {
                "path": path_str,
                "filename": path.name,
                "chunk_index": idx,
                "text": chunk,
                "source": rel_source,
                "content_hash": h,
            }
            points.append({"id": make_point_id(path, idx), "vector": vector, "payload": payload})

        upsert_points(args.collection, points)
        total_points += len(points)
        total_files += 1
        label = "updated" if path_str in existing_hashes else "indexed"
        print(f"{label} {path} ({len(points)} chunks)")

    # In sync mode, delete orphan points (files that were removed from disk).
    orphans_deleted = 0
    if args.sync and existing_hashes:
        orphan_paths = set(existing_hashes.keys()) - current_paths
        if orphan_paths:
            orphans_deleted = delete_points_by_paths(args.collection, orphan_paths)
            for op in sorted(orphan_paths):
                print(f"deleted {op} (removed from disk)")

    parts = [f"{total_files} files ingested", f"{total_points} chunks"]
    if skipped_files:
        parts.append(f"{skipped_files} unchanged")
    if orphans_deleted:
        parts.append(f"{orphans_deleted} orphans deleted")
    print(f"done: {', '.join(parts)} -> collection '{args.collection}'")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
