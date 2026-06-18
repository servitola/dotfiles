#!/usr/bin/env python3
"""rag-answer-eval.py — grade the ANSWER, not just retrieval.

The regular `rag eval` only checks whether a chunk containing the gold
substring was retrieved. It says nothing about whether the final LLM answer is
actually correct and useful. This tool closes that gap:

  for a sample of eval cases:
    retrieve  →  ask the chat model  →  judge the answer

The judge sees the question, the answer, and the gold `must_contain` hint, and
returns GOOD / PARTIAL / BAD. Reports a quality score and appends one block to
rag-answer-eval-history.md.

It is opt-in (not in the cron loop) because it spends ~2 chat calls per case.
Sample small and often, or large occasionally.

Usage:
  rag answer-eval                      # sample 20 cases, default models
  rag answer-eval --sample 40
  rag answer-eval --answer-model fast --judge-model fast
  rag answer-eval --seed 2026-06-07    # reproducible sample
  rag answer-eval --verbose            # print each verdict + reason
  rag answer-eval --manual-only        # only grade your hand-written cases

Exit code is always 0 unless inputs are missing — this is a report, not a gate.
"""
from __future__ import annotations

import argparse
import datetime
import importlib.util
import json
import os
import random
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAG_ROOT = HERE.parent
EVAL_FILE = RAG_ROOT / "rag.eval.json"
HISTORY_FILE = RAG_ROOT / "rag-answer-eval-history.md"

LITELLM_URL = os.environ.get("LITELLM_URL", "http://localhost:4000")
LITELLM_MASTER_KEY = os.environ.get("LITELLM_MASTER_KEY", "sk-local-workbot")


def _load(name: str, file: str):
    spec = importlib.util.spec_from_file_location(name, str(HERE / file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


rag_eval = _load("rag_eval", "rag-eval.py")


def chat(prompt: str, model: str, max_tokens: int = 600, retries: int = 3) -> str | None:
    """LiteLLM chat call, resilient to reasoning-model token exhaustion.

    Free-tier reasoning models (gpt/coding/nemotron) spend output tokens on
    hidden reasoning and can return finish_reason=length with empty content.
    On that case we retry with doubled max_tokens (capped) instead of giving up.
    Returns text, or None after exhausting retries.
    """
    tokens = max_tokens
    for attempt in range(retries):
        payload = json.dumps({
            "model": model,
            "max_tokens": tokens,
            "messages": [{"role": "user", "content": prompt}],
            # Bypass LiteLLM's semantic cache: it matches by embedding similarity,
            # so an answer prompt sharing context chunks with a concurrently-cached
            # rag-improve PROPOSE prompt would return the wrong completion. Grading
            # must always reflect a fresh answer.
            "cache": {"no-cache": True},
        }).encode()
        try:
            req = urllib.request.Request(
                f"{LITELLM_URL}/v1/chat/completions", data=payload, method="POST")
            req.add_header("Content-Type", "application/json")
            req.add_header("Authorization", f"Bearer {LITELLM_MASTER_KEY}")
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            choice = data.get("choices", [{}])[0]
            msg = choice.get("message", {}) or {}
            text = msg.get("content") or msg.get("reasoning_content")
            if text and text.strip():
                return text
            # Empty content at length cap → reasoning ate the budget. Grow it.
            if choice.get("finish_reason") == "length" and tokens < 8000:
                tokens = min(tokens * 2, 8000)
        except Exception:
            pass
    return None


ANSWER_PROMPT = """Answer the question using ONLY the context below. If the context
is insufficient, say so plainly. Be concise and technically precise.
When the question asks for multiple items, values, or parts (e.g. "which two
values", a list, both sides of a pair), enumerate ALL of them present in the
context — do not stop after the first.

Question: {q}

Context:
{context}"""

JUDGE_PROMPT = """You grade a RAG system's answer for correctness and usefulness.

Question: {q}

The answer SHOULD reflect this known fact from the source (a correct answer
need not quote it verbatim, but must be consistent with it):
  {gold}

Answer given:
---
{answer}
---

Grade the answer:
  GOOD    — correct and actually answers the question
  PARTIAL — on-topic and partly right but incomplete or hedged
  BAD     — wrong, off-topic, or refuses ("insufficient context")

Output one word (GOOD / PARTIAL / BAD), then a colon and one short reason."""


def grade_case(case: dict, collection: str, top_k: int,
               answer_model: str, judge_model: str) -> tuple[str, str, str]:
    """Return (verdict, answer, reason)."""
    q = case["q"]
    gold = case.get("must_contain") or case.get("must_hit_path") or "(no gold hint)"
    vec = rag_eval.embed(q)
    if vec is None:
        return "SKIP", "", "embed unavailable"
    hits = rag_eval.search_then_rerank(collection, q, vec, top_k)
    if not hits:
        return "BAD", "", "no context retrieved"
    # Feed top 10 chunks × 900 chars — matches what `rag ask` actually serves
    # (top_k=10), so grading reflects the real answer path. The earlier 6-chunk
    # window under-fed context: needles sitting in retrieved-but-unshown chunks
    # 7-12 made the model answer "insufficient context" → false PARTIAL/BAD.
    # max_tokens below is generous enough that reasoning models still finish.
    blocks = []
    for i, h in enumerate(hits[:10], 1):
        pl = h.get("payload", {})
        blocks.append(f"[{i}] {pl.get('path','?')}\n{(pl.get('text') or '')[:900]}")
    context = "\n\n".join(blocks)
    # Generous token budget: reasoning models (gpt/coding) burn output tokens on
    # hidden reasoning and return empty content at finish_reason=length otherwise.
    answer = chat(ANSWER_PROMPT.format(q=q, context=context), answer_model, max_tokens=2000)
    if not answer:
        return "SKIP", "", "answer model unavailable"
    verdict_raw = chat(JUDGE_PROMPT.format(q=q, gold=gold, answer=answer),
                       judge_model, max_tokens=500)
    if not verdict_raw:
        return "SKIP", answer, "judge unavailable"
    # Reasoning judge models (gpt/coding/nemotron) leak chain-of-thought as a
    # <think>...</think> block before the verdict. Strip it so the parsed
    # verdict/reason — and the history file — reflect the conclusion, not the
    # scratchpad. Handles an unclosed <think> too (reasoning ran to the cap).
    import re
    verdict_raw = re.sub(r"<think>.*?</think>", "", verdict_raw, flags=re.DOTALL | re.IGNORECASE)
    verdict_raw = re.sub(r"<think>.*$", "", verdict_raw, flags=re.DOTALL | re.IGNORECASE).strip()
    if not verdict_raw:
        return "SKIP", answer, "judge returned only reasoning, no verdict"
    first = verdict_raw.strip().splitlines()[0] if verdict_raw.strip() else ""
    parts = first.split(":", 1)
    verdict = parts[0].strip().upper()
    if verdict not in ("GOOD", "PARTIAL", "BAD"):
        m = re.search(r"\b(GOOD|PARTIAL|BAD)\b", verdict_raw, re.IGNORECASE)
        verdict = m.group(1).upper() if m else "PARTIAL"
    reason = parts[1].strip() if len(parts) > 1 else verdict_raw.strip()[:160]
    return verdict, answer, reason


def append_history(stats: dict) -> None:
    if not HISTORY_FILE.exists():
        HISTORY_FILE.write_text("# RAG answer-eval history\n\n", encoding="utf-8")
    lines = [
        f"## {stats['ts']}",
        f"- sample: {stats['n']} cases ({stats['scope']}), "
        f"answer={stats['answer_model']} judge={stats['judge_model']}",
        f"- GOOD {stats['good']} / PARTIAL {stats['partial']} / BAD {stats['bad']}"
        + (f" / SKIP {stats['skip']}" if stats['skip'] else ""),
        f"- quality score: {stats['score']:.0f}% (GOOD + 0.5·PARTIAL over graded)",
        "",
    ]
    with HISTORY_FILE.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sample", type=int, default=20)
    ap.add_argument("--seed", default="answer-eval")
    # answer defaults to `gpt` (what `rag ask` actually serves); judge to the
    # non-reasoning github-gpt4o-mini (clean verdicts, no <think> leak, no
    # reasoning-token exhaustion) — A/B (2026-06-17) showed `fast/fast` was an
    # unreliable grader, not a real quality signal.
    ap.add_argument("--answer-model", default=os.environ.get("RAG_ANSWER_MODEL", "gpt"))
    ap.add_argument("--judge-model", default=os.environ.get("RAG_JUDGE_MODEL", "github-gpt4o-mini"))
    ap.add_argument("--manual-only", action="store_true", help="grade only hand-written cases")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--eval-file", default=str(EVAL_FILE))
    args = ap.parse_args()

    ef = Path(args.eval_file)
    if not ef.is_file():
        print(f"rag-answer-eval: eval file not found: {ef}", file=sys.stderr)
        return 1
    spec = json.loads(ef.read_text(encoding="utf-8"))
    collection = spec.get("collection", "dotfiles")
    top_k = spec.get("top_k", 12)
    cases = spec.get("cases", [])
    if args.manual_only:
        cases = [c for c in cases if c.get("manual")]
    if not cases:
        print("rag-answer-eval: no cases to grade", file=sys.stderr)
        return 1

    rng = random.Random(args.seed)
    sample = cases if args.sample >= len(cases) else rng.sample(cases, args.sample)

    counts = {"GOOD": 0, "PARTIAL": 0, "BAD": 0, "SKIP": 0}
    print(f"rag-answer-eval: grading {len(sample)} cases "
          f"(answer={args.answer_model}, judge={args.judge_model})", file=sys.stderr)
    for i, c in enumerate(sample, 1):
        verdict, answer, reason = grade_case(
            c, collection, top_k, args.answer_model, args.judge_model)
        counts[verdict] = counts.get(verdict, 0) + 1
        mark = {"GOOD": "✓", "PARTIAL": "~", "BAD": "✗", "SKIP": "·"}.get(verdict, "?")
        print(f"  {mark} [{verdict:7}] {c['q'][:64]}")
        # Always surface SKIP reason (transport/model issue worth seeing);
        # other reasons only under --verbose.
        if verdict == "SKIP" or args.verbose:
            print(f"        reason: {reason[:120]}")
        if i % 10 == 0 or i == len(sample):
            graded = counts["GOOD"] + counts["PARTIAL"] + counts["BAD"]
            print(f"    … {i}/{len(sample)}  GOOD={counts['GOOD']} "
                  f"PARTIAL={counts['PARTIAL']} BAD={counts['BAD']}", file=sys.stderr)

    graded = counts["GOOD"] + counts["PARTIAL"] + counts["BAD"]
    score = (counts["GOOD"] + 0.5 * counts["PARTIAL"]) / graded * 100 if graded else 0.0
    print()
    print(f"GOOD {counts['GOOD']} / PARTIAL {counts['PARTIAL']} / BAD {counts['BAD']}"
          + (f" / SKIP {counts['SKIP']}" if counts["SKIP"] else ""))
    print(f"quality score: {score:.0f}%  (GOOD + 0.5·PARTIAL over {graded} graded)")

    append_history({
        "ts": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "n": len(sample),
        "scope": "manual-only" if args.manual_only else "all",
        "answer_model": args.answer_model, "judge_model": args.judge_model,
        "good": counts["GOOD"], "partial": counts["PARTIAL"],
        "bad": counts["BAD"], "skip": counts["SKIP"], "score": score,
    })
    return 0


if __name__ == "__main__":
    sys.exit(main())
