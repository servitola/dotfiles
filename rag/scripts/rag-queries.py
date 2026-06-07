#!/usr/bin/env python3
"""rag-queries.py — digest of real queries logged by rag-ask.py.

Reads rag/logs/queries.jsonl (one JSON record per ask/context call) and prints
a deduped, ranked digest. The point: surface the questions you actually ask so
you can pick which deserve to become eval cases — real queries beat synthetic
ones the auto-loop invents.

A query is flagged WEAK when retrieval looks shaky:
  • n_hits == 0                       — nothing retrieved
  • answered is False                 — LLM said context was insufficient
  • already in rag.eval.json          — covered, shown dimmed (not weak)

Usage:
  rag queries                      # digest, newest first, weak ones first
  rag queries --weak               # only weak queries (the work queue)
  rag queries --limit 40
  rag queries --since 2026-06-01   # only queries on/after this date

Output is plain text meant for eyeballing in a terminal or pasting to an agent.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAG_ROOT = HERE.parent
QUERY_LOG = RAG_ROOT / "logs" / "queries.jsonl"
EVAL_FILE = RAG_ROOT / "rag.eval.json"


def _norm(q: str) -> str:
    return " ".join((q or "").lower().split())


def load_records(since: str | None) -> list[dict]:
    if not QUERY_LOG.exists():
        return []
    out = []
    for line in QUERY_LOG.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        if since and rec.get("ts", "") < since:
            continue
        out.append(rec)
    return out


def load_eval_questions() -> set[str]:
    if not EVAL_FILE.exists():
        return set()
    try:
        d = json.loads(EVAL_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return set()
    return {_norm(c.get("q", "")) for c in d.get("cases", [])}


def is_weak(rec: dict) -> bool:
    if rec.get("n_hits", 0) == 0:
        return True
    if rec.get("answered") is False:
        return True
    return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--weak", action="store_true", help="only show weak queries (the work queue)")
    ap.add_argument("--limit", type=int, default=30)
    ap.add_argument("--since", help="only queries with ts >= this prefix (e.g. 2026-06-01)")
    args = ap.parse_args()

    records = load_records(args.since)
    if not records:
        print(f"rag-queries: no log yet at {QUERY_LOG.relative_to(RAG_ROOT)} "
              f"(ask something with `rag ask` / `rag context`)", file=sys.stderr)
        return 0

    covered = load_eval_questions()

    # Dedup by normalized question, keep the most recent record + a count.
    agg: dict[str, dict] = {}
    for rec in records:
        key = _norm(rec.get("q", ""))
        if not key:
            continue
        cur = agg.get(key)
        if cur is None:
            agg[key] = {"rec": rec, "count": 1}
        else:
            cur["count"] += 1
            if rec.get("ts", "") >= cur["rec"].get("ts", ""):
                cur["rec"] = rec

    rows = list(agg.values())
    for r in rows:
        rec = r["rec"]
        r["weak"] = is_weak(rec)
        r["covered"] = _norm(rec.get("q", "")) in covered

    if args.weak:
        rows = [r for r in rows if r["weak"]]

    # Weak first, then by recency.
    rows.sort(key=lambda r: (not r["weak"], r["rec"].get("ts", "")), reverse=False)
    rows.sort(key=lambda r: r["rec"].get("ts", ""), reverse=True)
    rows.sort(key=lambda r: not r["weak"])  # stable: weak group on top

    total = len(agg)
    weak_n = sum(1 for r in agg.values() if is_weak(r["rec"]))
    print(f"# real queries — {total} unique, {weak_n} weak, {len(records)} total calls")
    print(f"# log: {QUERY_LOG}")
    print()

    shown = rows[: args.limit]
    for r in shown:
        rec = r["rec"]
        flag = "WEAK" if r["weak"] else ("seen" if r["covered"] else "    ")
        cnt = f"×{r['count']}" if r["count"] > 1 else "  "
        nh = rec.get("n_hits", "?")
        ans = rec.get("answered")
        ans_s = {True: "ans", False: "REFUSED", None: "ctx"}.get(ans, "?")
        ts = rec.get("ts", "")[:16]
        print(f"[{flag}] {cnt:3} hits={nh:<2} {ans_s:7} {ts}  {rec.get('q','')}")
        if r["weak"]:
            tops = [p.split('/')[-1] for p in (rec.get("top3") or [])]
            if tops:
                print(f"         ↳ top: {' | '.join(tops)}")

    if len(rows) > args.limit:
        print(f"\n… {len(rows) - args.limit} more (raise --limit)")
    print()
    print("To turn a query into an eval case: pick it, find a stable substring in")
    print("the right source file, add {q, must_contain, manual:true} to rag.eval.json.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
