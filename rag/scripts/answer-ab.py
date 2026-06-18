#!/usr/bin/env python3
"""answer-ab.py — A/B answer-generation quality WITHOUT touching history.

A thin, side-effect-free wrapper over rag-answer-eval.py's grade_case: grades a
FIXED sample (same --seed + --sample → identical cases across runs, so models
are comparable) and prints a JSON scorecard. Unlike `rag answer-eval` it does
NOT append to rag-answer-eval-history.md — safe to run many in parallel for an
A/B sweep over answer models / judges.

Reuses grade_case (and through it rag-eval helpers) via importlib, per AGENTS.md.

Usage:
  answer-ab.py rag.eval.spotware-dev-docs.json \
    --answer-model gpt --judge-model github-gpt4o-mini --sample 10 --seed abtest
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def _load(name, file):
    spec = importlib.util.spec_from_file_location(name, str(HERE / file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# rag-answer-eval.py imports rag-eval.py itself; loading it gives us grade_case.
rae = _load("rag_answer_eval", "rag-answer-eval.py")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("eval_file")
    ap.add_argument("--answer-model", required=True)
    ap.add_argument("--judge-model", default="github-gpt4o-mini")
    ap.add_argument("--sample", type=int, default=10)
    ap.add_argument("--seed", default="answer-ab")
    args = ap.parse_args()

    spec = json.loads(Path(args.eval_file).read_text(encoding="utf-8"))
    collection = spec.get("collection", "dotfiles")
    top_k = spec.get("top_k", 12)
    cases = spec.get("cases", [])
    # Identical sampling rule to rag-answer-eval so seeds line up.
    sample = cases if args.sample >= len(cases) else random.Random(args.seed).sample(cases, args.sample)

    counts = {"GOOD": 0, "PARTIAL": 0, "BAD": 0, "SKIP": 0}
    failures = []
    for c in sample:
        verdict, _answer, reason = rae.grade_case(
            c, collection, top_k, args.answer_model, args.judge_model)
        counts[verdict] = counts.get(verdict, 0) + 1
        if verdict in ("BAD", "PARTIAL"):
            failures.append({"q": c["q"][:80], "verdict": verdict, "reason": reason[:100]})

    graded = counts["GOOD"] + counts["PARTIAL"] + counts["BAD"]
    score = (counts["GOOD"] + 0.5 * counts["PARTIAL"]) / graded * 100 if graded else 0.0
    print(json.dumps({
        "collection": collection,
        "answer_model": args.answer_model,
        "judge_model": args.judge_model,
        "sample": len(sample),
        "graded": graded,
        "good": counts["GOOD"], "partial": counts["PARTIAL"],
        "bad": counts["BAD"], "skip": counts["SKIP"],
        "score": round(score, 1),
        "failures": failures,
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
