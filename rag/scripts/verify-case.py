#!/usr/bin/env python3
"""verify-case.py — verify candidate eval cases against LIVE retrieval.

Reads a JSON array of candidate cases from stdin, runs each through the SAME
retrieval + assertion path as `rag eval` (reusing rag-eval.py helpers via
importlib — no duplicated embed/search logic, per AGENTS.md), and prints a JSON
array of verdicts to stdout.

Input  (stdin): [{"q": "...", "must_contain": "..."}, {"q": "...", "must_hit_path": "..."}, ...]
Output (stdout): [{"q": "...", "pass": true, "reason": "", "paths": ["...", ...]}, ...]

A case "passes" only when the assertion substring actually surfaces in the
top-k retrieved chunks. This is the adversarial gate that keeps generated cases
from polluting the regression suite with false failures.

Usage:
  echo '[{"q":"...","must_contain":"..."}]' | \
    verify-case.py --collection dotfiles --top-k 12
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def _load(name: str, file: str):
    spec = importlib.util.spec_from_file_location(name, str(HERE / file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


rag_eval = _load("rag_eval", "rag-eval.py")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--collection", required=True)
    ap.add_argument("--top-k", type=int, default=12)
    args = ap.parse_args()

    try:
        cases = json.loads(sys.stdin.read())
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"bad stdin JSON: {e}"}), file=sys.stderr)
        return 2
    if not isinstance(cases, list):
        print(json.dumps({"error": "stdin must be a JSON array"}), file=sys.stderr)
        return 2

    out = []
    for case in cases:
        q = case.get("q", "")
        if not q or not ("must_contain" in case or "must_hit_path" in case):
            out.append({"q": q, "pass": False, "reason": "malformed case", "paths": []})
            continue
        vec = rag_eval.embed(q)
        if vec is None:
            out.append({"q": q, "pass": None, "reason": "embed unavailable (rate-limit?)", "paths": []})
            continue
        hits = rag_eval.search_then_rerank(args.collection, q, vec, args.top_k)
        ok, reason = rag_eval.check_assertion(case, hits)
        paths = [h.get("payload", {}).get("path", "?") for h in hits[:5]]
        out.append({
            "q": q,
            "pass": bool(ok),
            "reason": "" if ok else reason,
            "paths": paths,
        })

    print(json.dumps(out, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
