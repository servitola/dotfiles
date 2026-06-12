#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=1.2"]
# ///
"""rag-mcp — MCP server exposing the dotfiles RAG to Claude Code / Codex.

Two tools are exported:
  rag_context(query, top_k=8, collection)  → top-K retrieved chunks (no LLM call)
  rag_ask(query, top_k=6, collection, model) → LLM answer grounded in retrieved chunks

Both reuse the existing rag-eval.py / rag-ask.py logic via importlib so behaviour
stays in lockstep with the CLI: same embed model, same hybrid/rerank pipeline.

Register with Claude Code (user scope, available in all projects):
  claude mcp add rag-local --scope user -- /Users/servitola/projects/dotfiles/rag/mcp-server.py

Or add to ~/.claude.json under "mcpServers":
  "rag": {"command": "/Users/servitola/projects/dotfiles/rag/mcp-server.py"}
"""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import os
import sys
import urllib.parse
import urllib.request
from pathlib import Path
from types import ModuleType

from mcp.server.fastmcp import FastMCP

SCRIPTS_DIR = Path(__file__).resolve().parent / "scripts"


def _load(name: str, file: str) -> ModuleType:
    loader = importlib.machinery.SourceFileLoader(name, str(SCRIPTS_DIR / file))
    spec = importlib.util.spec_from_loader(name, loader)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {file}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# Source ~/.config/openai_key.sh exports so VOYAGE_API_KEY and friends are present
# when this server is launched directly by Claude Code (no parent shell).
_KEY_FILE = Path.home() / ".config" / "openai_key.sh"
if _KEY_FILE.is_file():
    for line in _KEY_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line.startswith("export "):
            continue
        kv = line[len("export "):]
        if "=" not in kv:
            continue
        k, _, v = kv.partition("=")
        k = k.strip()
        v = v.strip().strip('"').strip("'")
        os.environ.setdefault(k, v)

rag_eval = _load("rag_eval", "rag-eval.py")
rag_ask = _load("rag_ask", "rag-ask.py")

DEFAULT_COLLECTION = os.environ.get("RAG_COLLECTION", "dotfiles")
DEFAULT_CHAT_MODEL = os.environ.get("RAG_CHAT_MODEL", "gpt")

mcp = FastMCP(
    "rag",
    instructions=(
        "Local RAG over the user's dotfiles and adjacent project knowledge. "
        "Use rag_context for fast retrieval (no LLM call) when you need raw "
        "chunks to ground your own response. Use rag_ask when you want a "
        "fully-formed answer with citations. Default collection is 'dotfiles'."
    ),
)


def _format_chunks(hits: list[dict]) -> str:
    if not hits:
        return "No matches found."
    blocks: list[str] = []
    for i, h in enumerate(hits, 1):
        pl = h.get("payload", {}) or {}
        path = pl.get("path", "?")
        text = (pl.get("text") or "").strip()
        score = pl.get("_rerank_score")
        score_s = f" rerank={score:.3f}" if isinstance(score, (int, float)) else ""
        sim = h.get("score")
        sim_s = f" sim={sim:.3f}" if isinstance(sim, (int, float)) else ""
        blocks.append(f"[{i}] path={path}{sim_s}{score_s}\n{text}")
    return "\n\n---\n\n".join(blocks)


@mcp.tool()
def rag_context(
    query: str,
    top_k: int = 8,
    collection: str = "",
) -> str:
    """Retrieve top-K chunks from the RAG index. No LLM call.

    Use this when you want to ground your own response in the user's actual
    files. Each chunk is returned with its source path and similarity / rerank
    scores.

    Args:
        query: The question or keyword phrase to search for.
        top_k: How many chunks to return (default 8, max 20).
        collection: Qdrant collection name. Defaults to RAG_COLLECTION env
            (typically 'dotfiles'). Other collections: workbot2, services,
            spotware-dev-docs.
    """
    coll = collection or DEFAULT_COLLECTION
    k = max(1, min(int(top_k), 20))
    vec = rag_eval.embed(query)
    if vec is None:
        return "ERROR: embed upstream unavailable (LiteLLM not running?)"
    hits = rag_eval.search_then_rerank(coll, query, vec, k)
    return _format_chunks(hits)


@mcp.tool()
def rag_ask(
    query: str,
    top_k: int = 10,
    collection: str = "",
    model: str = "",
) -> str:
    """Ask a natural-language question; an LLM answers grounded in retrieved chunks.

    Slower than rag_context (one extra LLM call) but returns a finished answer
    with inline citations. Prefer rag_context when you'll synthesize the answer
    yourself — it saves an LLM round trip.

    Args:
        query: The question to answer.
        top_k: How many chunks to retrieve as context (default 10 — enough to
            cover both the trigger source and the action target for multi-hop
            questions like "what does Hyper+B do" where the answer spans a
            Karabiner rule and a Hammerspoon binding in different files).
        collection: Qdrant collection (defaults to dotfiles).
        model: LiteLLM model alias (default 'gpt'; alternatives: 'fast',
            'reasoning', 'coding').
    """
    coll = collection or DEFAULT_COLLECTION
    chat_model = model or DEFAULT_CHAT_MODEL
    k = max(1, min(int(top_k), 20))

    vec = rag_eval.embed(query)
    if vec is None:
        return "ERROR: embed upstream unavailable (LiteLLM not running?)"
    hits = rag_eval.search_then_rerank(coll, query, vec, k)
    context_block = _format_chunks(hits)

    prompt = (
        "You answer using ONLY the retrieved context when possible. "
        "If context is insufficient, say so. Cite source paths.\n\n"
        "IMPORTANT — multi-hop questions: when the answer spans multiple files "
        "(e.g. a Karabiner rule remaps a key to an F-key, and a Hammerspoon "
        "binding then attaches an action to that F-key), trace the chain to "
        "its END action. Don't stop at the first remap if a later step gives "
        "the user-visible result.\n\n"
        f"Question: {query}\n\n"
        f"Context:\n{context_block}\n\n"
        "Answer:"
    )
    payload = {
        "model": chat_model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 800,
    }
    try:
        data = rag_eval.http_json(
            "POST",
            f"{rag_eval.LITELLM_URL}/v1/chat/completions",
            payload=payload,
            headers={"Authorization": f"Bearer {rag_eval.LITELLM_MASTER_KEY}"},
        )
    except SystemExit as exc:
        return f"ERROR: chat upstream failed ({exc})"
    msg = (data.get("choices") or [{}])[0].get("message", {})
    answer = msg.get("content") or msg.get("reasoning_content") or "(empty answer)"

    # Append condensed citations footer for easy copy-paste.
    paths = []
    for h in hits[:k]:
        p = (h.get("payload") or {}).get("path")
        if p and p not in paths:
            paths.append(p)
    if paths:
        answer += "\n\nSources:\n" + "\n".join(f"- {p}" for p in paths[:5])
    return answer


if __name__ == "__main__":
    mcp.run()
