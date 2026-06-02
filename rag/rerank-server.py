#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "sentence-transformers>=3.0",
#   "flask>=3.0",
#   "torch>=2.4",
# ]
# ///
"""rerank-server — lazy local reranker daemon using BAAI/bge-reranker-v2-m3.

Spawned automatically by rag-eval / rag-improve / MCP server when needed,
self-terminates after IDLE_TIMEOUT seconds without traffic. Listens on
localhost only — never exposed to LAN.

Endpoints:
  GET  /health                        → liveness + uptime + last-request age
  POST /rerank {query, documents, top_k}
       → {"results": [{"index": int, "score": float}, ...]}  (sorted desc)

Usage:
  ./rag/rerank-server.py                            # default port 8765, 5min idle
  ./rag/rerank-server.py --port 8765 --idle-shutdown 300
  ./rag/rerank-server.py --device cpu               # force CPU (default: auto)

CLI clients prefer to call _ensure_rerank_daemon() in rag-eval.py rather than
spawning this manually — it handles probing + auto-start + ready-poll.
"""

from __future__ import annotations

import argparse
import logging
import os
import sys
import threading
import time

from flask import Flask, jsonify, request


def auto_select_device() -> str:
    """Pick the fastest device for bge-reranker-v2-m3.

    On Apple Silicon: CPU is ~10x faster than MPS for this cross-encoder
    (sentence-transformers' MPS path falls back to slow ops for cross-attention
    on long sequences). Bench on M3 Pro for 12 docs × 2000 chars: MPS 18s vs
    CPU 1.7s. We default to CPU; override with --device mps if benchmarks
    change after a future torch / sentence-transformers release.
    """
    try:
        import torch

        if torch.cuda.is_available():
            return "cuda"
    except Exception:
        pass
    return "cpu"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Lazy local reranker HTTP daemon.")
    p.add_argument("--port", type=int, default=int(os.environ.get("RAG_RERANK_PORT", "8765")))
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--model", default=os.environ.get("RAG_RERANK_MODEL_LOCAL", "BAAI/bge-reranker-v2-m3"))
    p.add_argument("--device", default="auto", choices=["auto", "mps", "cuda", "cpu"])
    p.add_argument(
        "--idle-shutdown",
        type=int,
        default=int(os.environ.get("RAG_RERANK_IDLE_SHUTDOWN", "300")),
        help="Seconds without /rerank traffic before exit. 0 disables.",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    device = auto_select_device() if args.device == "auto" else args.device

    # Quiet down noisy libraries.
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    os.environ.setdefault("TRANSFORMERS_NO_ADVISORY_WARNINGS", "1")
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

    print(f"rerank-server: loading {args.model} on {device}…", file=sys.stderr)
    from sentence_transformers import CrossEncoder

    t0 = time.time()
    model = CrossEncoder(args.model, device=device)
    load_s = time.time() - t0
    print(f"rerank-server: ready on http://{args.host}:{args.port} (load={load_s:.1f}s)", file=sys.stderr)

    app = Flask(__name__)
    started_at = time.time()
    last_request_at = time.time()
    state_lock = threading.Lock()

    @app.get("/health")
    def health():
        with state_lock:
            age = time.time() - last_request_at
        return jsonify(
            status="ok",
            model=args.model,
            device=device,
            load_seconds=round(load_s, 2),
            uptime_seconds=round(time.time() - started_at, 1),
            last_request_age_seconds=round(age, 1),
        )

    @app.post("/rerank")
    def rerank():
        nonlocal last_request_at
        try:
            body = request.get_json(force=True, silent=False)
        except Exception as exc:
            return jsonify(error=f"bad json: {exc}"), 400
        if not isinstance(body, dict):
            return jsonify(error="body must be an object"), 400
        query = body.get("query")
        docs = body.get("documents")
        top_k = int(body.get("top_k") or 0) or None
        if not isinstance(query, str) or not isinstance(docs, list):
            return jsonify(error="need {query: str, documents: [str, ...]}"), 400
        if not docs:
            with state_lock:
                last_request_at = time.time()
            return jsonify(results=[])

        pairs = [(query, d if isinstance(d, str) else str(d)) for d in docs]
        scores = model.predict(pairs, convert_to_numpy=True, show_progress_bar=False)
        ranked = sorted(
            ({"index": i, "score": float(s)} for i, s in enumerate(scores)),
            key=lambda r: r["score"],
            reverse=True,
        )
        if top_k is not None and top_k > 0:
            ranked = ranked[:top_k]
        with state_lock:
            last_request_at = time.time()
        return jsonify(results=ranked, count=len(ranked))

    if args.idle_shutdown > 0:
        def watchdog():
            while True:
                time.sleep(30)
                with state_lock:
                    age = time.time() - last_request_at
                if age >= args.idle_shutdown:
                    print(f"rerank-server: idle {age:.0f}s ≥ {args.idle_shutdown}s — exiting", file=sys.stderr)
                    os._exit(0)

        threading.Thread(target=watchdog, daemon=True).start()

    # threaded=False because CrossEncoder/PyTorch is not thread-safe on MPS.
    app.run(host=args.host, port=args.port, threaded=False, debug=False, use_reloader=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
