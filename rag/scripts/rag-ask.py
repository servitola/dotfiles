#!/usr/bin/env python3
"""
rag-ask.py — retrieve context from Qdrant, then ask LiteLLM.

Examples:
  ./scripts/rag-ask.py "how is docker configured for me?"
  ./scripts/rag-ask.py --collection dotfiles --top-k 8 "how is keyboard setup documented?"
  ./scripts/rag-ask.py --json "summarize indexed notes"
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


LITELLM_URL = os.environ.get("LITELLM_URL", "http://localhost:4000")
LITELLM_MASTER_KEY = os.environ.get("LITELLM_MASTER_KEY", "sk-local-workbot")
QDRANT_URL = os.environ.get("QDRANT_URL", "http://localhost:6333")
EMBED_MODEL = os.environ.get("RAG_EMBED_MODEL", "embed")
CHAT_MODEL = os.environ.get("RAG_CHAT_MODEL", "gpt")
DEFAULT_COLLECTION = os.environ.get("RAG_COLLECTION", "workflow")

SYSTEM_PROMPT = """You answer using only the retrieved context when possible.
If the context is insufficient, say that directly.
Prefer concise, technically precise answers.
When useful, cite the source paths from the provided context.

IMPORTANT — multi-hop questions: when the answer spans multiple files (e.g.
a Karabiner rule remaps a key to an F-key, and a Hammerspoon binding then
attaches an action to that F-key), trace the chain to its END action.
Don't stop at the first remap if a later chunk reveals the user-visible
result. Mention every hop briefly, but lead with the final action."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("question", help="Question to ask")
    parser.add_argument("--collection", default=DEFAULT_COLLECTION)
    parser.add_argument("--top-k", type=int, default=10)
    parser.add_argument("--model", default=CHAT_MODEL)
    parser.add_argument("--mode", choices=["vector", "fts", "hybrid"], default="hybrid",
                        help="Search mode: hybrid (default; vector+FTS RRF), vector (semantic only), fts (keyword only)")
    parser.add_argument("--json", action="store_true", help="Print raw JSON response")
    parser.add_argument("--show-context", action="store_true", help="Print retrieved chunks before the answer")
    parser.add_argument("--context-only", action="store_true", help="Print only retrieved context, skip LLM call")
    return parser.parse_args()


def http_json(method: str, url: str, payload: dict | None = None, headers: dict | None = None) -> dict:
    body = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(url, method=method)
    req.add_header("Content-Type", "application/json")
    if headers:
        for key, value in headers.items():
            req.add_header(key, value)

    try:
        with urllib.request.urlopen(req, data=body, timeout=90) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"{method} {url} failed: HTTP {exc.code}\n{detail}") from exc
    except urllib.error.URLError as exc:
        reason = str(exc).lower()
        if "connection refused" in reason or "no route" in reason or "network is unreachable" in reason:
            host = urllib.parse.urlparse(url).netloc
            service = "LiteLLM" if ":4000" in host else ("Qdrant" if ":6333" in host else host)
            raise SystemExit(
                f"{service} is not responding at {url}\n"
                f"start it:  cd ~/projects/dotfiles/litellm && docker compose up -d  "
                f"# and qdrant/"
            ) from exc
        raise SystemExit(f"{method} {url} failed: {exc}") from exc

    if not raw:
        return {}
    return json.loads(raw.decode("utf-8"))


def embed_query(text: str) -> list[float]:
    data = http_json(
        "POST",
        f"{LITELLM_URL}/v1/embeddings",
        payload={"model": EMBED_MODEL, "input": text, "encoding_format": "float"},
        headers={"Authorization": f"Bearer {LITELLM_MASTER_KEY}"},
    )
    return data["data"][0]["embedding"]


def search_qdrant(collection: str, vector: list[float], top_k: int) -> list[dict]:
    data = http_json(
        "POST",
        f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points/search",
        payload={"vector": vector, "limit": top_k, "with_payload": True},
    )
    return data.get("result", [])


def search_fts(collection: str, query: str, top_k: int) -> list[dict]:
    """Full-text search via Qdrant text index on the 'text' payload field."""
    data = http_json(
        "POST",
        f"{QDRANT_URL}/collections/{urllib.parse.quote(collection)}/points/scroll",
        payload={
            "filter": {"must": [{"key": "text", "match": {"text": query}}]},
            "limit": top_k,
            "with_payload": True,
        },
    )
    points = data.get("result", {}).get("points", [])
    # scroll doesn't return scores — assign descending rank so build_context
    # can still show something meaningful
    for idx, point in enumerate(points):
        point["score"] = 1.0 - idx * 0.01
    return points


def search_hybrid(collection: str, vector: list[float], query: str, top_k: int) -> list[dict]:
    """Hybrid search: vector + FTS-filtered vector, fused with RRF.

    Prefetch 1: pure semantic search (top 20).
    Prefetch 2: semantic search filtered to chunks containing query keywords (top 20).
    Server-side RRF fusion promotes chunks that appear in both result sets.
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


def build_context(hits: list[dict]) -> str:
    blocks = []
    for idx, hit in enumerate(hits, start=1):
        payload = hit.get("payload", {})
        source = payload.get("path", "unknown")
        score = hit.get("score", 0.0)
        text = payload.get("text", "").strip()
        blocks.append(
            f"[Source {idx}] path={source} score={score:.4f}\n{text}"
        )
    return "\n\n".join(blocks)


def ask_llm(question: str, context: str, model: str) -> dict:
    user_prompt = (
        "Use the retrieved context below to answer the question.\n\n"
        f"Question:\n{question}\n\n"
        f"Retrieved context:\n{context}"
    )
    return http_json(
        "POST",
        f"{LITELLM_URL}/v1/chat/completions",
        payload={
            "model": model,
            "max_tokens": 1200,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
        },
        headers={"Authorization": f"Bearer {LITELLM_MASTER_KEY}"},
    )


def main() -> int:
    args = parse_args()

    if args.mode == "fts":
        hits = search_fts(args.collection, args.question, args.top_k)
    else:
        query_vector = embed_query(args.question)
        if args.mode == "hybrid":
            hits = search_hybrid(args.collection, query_vector, args.question, args.top_k)
        else:
            hits = search_qdrant(args.collection, query_vector, args.top_k)

    if not hits:
        print("No context found in Qdrant for this question.", file=sys.stderr)
        return 1

    context = build_context(hits)
    if args.context_only:
        print(context)
        return 0

    if args.show_context:
        print("=== Retrieved Context ===")
        print(context)
        print("\n=== Answer ===")

    response = ask_llm(args.question, context, args.model)
    if args.json:
        print(json.dumps(response, ensure_ascii=False, indent=2))
        return 0

    text = response.get("choices", [{}])[0].get("message", {}).get("content")
    if not text:
        error = response.get("error", {}).get("message", "No answer content returned.")
        print(error, file=sys.stderr)
        return 1

    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
