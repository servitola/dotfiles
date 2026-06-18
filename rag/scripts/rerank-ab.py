#!/usr/bin/env python3
"""rerank-ab.py — A/B the reranker against plain hybrid on the eval suite.

Efficient: per query it embeds ONCE and does ONE wide hybrid search, then
compares two orderings derived from that single candidate set:
  plain   = wide[:top_k]                      (current production behaviour)
  rerank  = bge-reranker-v2-m3 over wide, cut to top_k

So the only added cost vs a normal eval is the (serialized, CPU-bound) rerank
call — no double embedding. Reuses rag-eval.py helpers (embed, search_hybrid,
rerank_local, check_assertion) via importlib, per AGENTS.md.

Reranking can only change the `must_contain` pass/fail when the candidate pool
is WIDER than top_k (otherwise it just reorders the same set). So fetch_k must
be > top_k to measure anything — default 50.

Usage:
  rerank-ab.py rag.eval.spotwarevpn.json --fetch-k 50 [--sample N] [--seed S]
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def _load(name, file):
    spec = importlib.util.spec_from_file_location(name, str(HERE / file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


rag_eval = _load("rag_eval", "rag-eval.py")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("eval_file")
    ap.add_argument("--fetch-k", type=int, default=50, help="wide candidate pool size (must be > top_k)")
    ap.add_argument("--sample", type=int, default=0, help="random sample N cases (0 = all)")
    ap.add_argument("--seed", default="rerank-ab")
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = ap.parse_args()

    spec = json.loads(Path(args.eval_file).read_text(encoding="utf-8"))
    collection = spec.get("collection", "dotfiles")
    top_k = spec.get("top_k", 12)
    cases = [c for c in spec.get("cases", []) if "must_contain" in c or "must_hit_path" in c]
    if args.sample and args.sample < len(cases):
        cases = random.Random(args.seed).sample(cases, args.sample)

    fetch_k = max(args.fetch_k, top_k + 1)
    counts = {"plain_pass": 0, "rerank_pass": 0, "both": 0, "neither": 0,
              "rescued": 0, "broken": 0, "skip": 0, "n": 0}
    rescued, broken = [], []

    for c in cases:
        vec = rag_eval.embed(c["q"])
        if vec is None:
            counts["skip"] += 1
            continue
        wide = rag_eval.search_hybrid(collection, vec, c["q"], fetch_k)
        plain = wide[:top_k]
        rerank = rag_eval.rerank_local(c["q"], wide, top_k)
        p_ok, _ = rag_eval.check_assertion(c, plain)
        r_ok, _ = rag_eval.check_assertion(c, rerank)
        counts["n"] += 1
        counts["plain_pass"] += int(bool(p_ok))
        counts["rerank_pass"] += int(bool(r_ok))
        if p_ok and r_ok:
            counts["both"] += 1
        elif not p_ok and not r_ok:
            counts["neither"] += 1
        elif r_ok and not p_ok:
            counts["rescued"] += 1
            rescued.append({"q": c["q"], "needle": c.get("must_contain") or c.get("must_hit_path")})
        else:
            counts["broken"] += 1
            broken.append({"q": c["q"], "needle": c.get("must_contain") or c.get("must_hit_path")})

    n = counts["n"] or 1
    result = {
        "collection": collection, "top_k": top_k, "fetch_k": fetch_k, "graded": counts["n"],
        "plain_pct": round(100 * counts["plain_pass"] / n, 1),
        "rerank_pct": round(100 * counts["rerank_pass"] / n, 1),
        "delta_pp": round(100 * (counts["rerank_pass"] - counts["plain_pass"]) / n, 1),
        "rescued": counts["rescued"], "broken": counts["broken"],
        "skipped": counts["skip"],
        "rescued_cases": rescued, "broken_cases": broken,
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        print(f"[{collection}] graded={counts['n']} top_k={top_k} fetch_k={fetch_k} "
              f"(skip {counts['skip']})")
        print(f"  plain   pass: {result['plain_pct']}%  ({counts['plain_pass']}/{counts['n']})")
        print(f"  rerank  pass: {result['rerank_pct']}%  ({counts['rerank_pass']}/{counts['n']})")
        print(f"  delta: {result['delta_pp']:+}pp   rescued={counts['rescued']}  broken={counts['broken']}")
        for r in broken:
            print(f"    BROKEN  needle={r['needle']!r}  q={r['q'][:60]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
