#!/usr/bin/env python3
"""rag-prune-gaps.py — drop gap entries whose `expect` is now retrievable.

For each entry in rag/gaps/<collection>.md (and optionally the legacy
rag/rag-gaps.md), re-runs the question through the current retriever. If any
retrieved chunk contains the `expect` substring (case-insensitive in text or
path), the entry is dropped. Survivors are rewritten back.

A gap is also dropped when its `file=` belongs to a different collection that
the current Qdrant index doesn't cover — these were misfiled by older runs.

Why we don't re-judge:
  Re-running the LLM-as-judge would be both slow and noisy. The judge is the
  reason most gaps were logged in the first place — and many of those were
  "judge unavailable" timeouts, not real misses. Retrieval is the ground truth.

Usage:
  rag-prune-gaps.py                       # prune rag/gaps/<collection>.md
  rag-prune-gaps.py --collection workflow
  rag-prune-gaps.py --legacy              # also process rag/rag-gaps.md
  rag-prune-gaps.py --dry-run             # report only, write nothing
  rag-prune-gaps.py --top-k 12

Exit codes:
  0 — clean run (with or without survivors)
  1 — collection missing, file missing, or retrieval upstream down
"""
from __future__ import annotations

import argparse
import datetime
import importlib.util
import os
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAG_ROOT = HERE.parent
GAPS_DIR = RAG_ROOT / "gaps"
LEGACY_GAPS = RAG_ROOT / "rag-gaps.md"

# Reuse rag-eval.py's embed/search/rerank pipeline so prune sees exactly what
# `rag context` would see at retrieval time.
_spec = importlib.util.spec_from_file_location("rag_eval", str(HERE / "rag-eval.py"))
rag_eval = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rag_eval)


ENTRY_HDR = re.compile(r"^- \[(\d{4}-\d{2}-\d{2})\] file=`([^`]+)`")
Q_LINE = re.compile(r'^\s*Q:\s*"(.+?)"\s+expect="(.+?)"\s*$')
REASON_LINE = re.compile(r"^\s*reason:\s*(.+)$")
TOP3_LINE = re.compile(r"^\s*top-3:\s*(.+)$")


def parse_gaps(path: Path) -> tuple[list[str], list[dict]]:
    """Return (header_lines, entries).

    Each entry is {"raw": [lines], "date", "file", "q", "expect", "reason", "top3"}.
    Lines that don't belong to any entry (file header, blank lines between
    entries) end up in header_lines for stable rewrite ordering.
    """
    header: list[str] = []
    entries: list[dict] = []
    cur: dict | None = None
    in_entries = False

    for raw in path.read_text(encoding="utf-8").splitlines():
        m = ENTRY_HDR.match(raw)
        if m:
            if cur:
                entries.append(cur)
            cur = {
                "raw": [raw],
                "date": m.group(1),
                "file": m.group(2),
                "q": "", "expect": "", "reason": "", "top3": "",
            }
            in_entries = True
            continue
        if cur is None:
            if not in_entries:
                header.append(raw)
            continue
        cur["raw"].append(raw)
        if qm := Q_LINE.match(raw):
            cur["q"], cur["expect"] = qm.group(1), qm.group(2)
        elif rm := REASON_LINE.match(raw):
            cur["reason"] = rm.group(1).strip()
        elif tm := TOP3_LINE.match(raw):
            cur["top3"] = tm.group(1).strip()

    if cur:
        entries.append(cur)
    return header, entries


def is_closed(entry: dict, collection: str, top_k: int) -> tuple[bool, str]:
    """Return (closed, reason). `expect` substring vs current top-k retrieval."""
    if not entry.get("q") or not entry.get("expect"):
        return True, "malformed (no Q/expect)"
    vec = rag_eval.embed(entry["q"])
    if vec is None:
        # Upstream is down — we can't decide. Don't drop on a transient failure.
        return False, "embed unavailable"
    hits = rag_eval.search_then_rerank(collection, entry["q"], vec, top_k)
    expect = entry["expect"].lower()
    for h in hits:
        pl = h.get("payload", {}) or {}
        text = (pl.get("text") or "").lower()
        path = (pl.get("path") or "").lower()
        if expect in text:
            return True, f"hit text @ {pl.get('path', '?')}"
        if expect in path:
            return True, f"hit path @ {pl.get('path', '?')}"
    return False, "still no hit"


def rewrite(path: Path, header: list[str], surviving: list[dict]) -> None:
    """Write header + surviving entries back, preserving original raw text."""
    out: list[str] = []
    # Trim trailing blanks on the header but keep one blank between header and entries.
    while header and not header[-1].strip():
        header.pop()
    out.extend(header)
    if header:
        out.append("")
    for e in surviving:
        out.extend(e["raw"])
        if not (e["raw"] and not e["raw"][-1].strip()):
            out.append("")
    path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")


def prune_file(path: Path, collection: str, top_k: int, dry_run: bool) -> dict:
    header, entries = parse_gaps(path)
    if not entries:
        return {"file": str(path), "total": 0, "closed": 0, "open": 0, "embed_down": 0}
    closed: list[dict] = []
    survivors: list[dict] = []
    embed_down = 0
    for i, e in enumerate(entries, 1):
        ok, why = is_closed(e, collection, top_k)
        if ok:
            closed.append({"entry": e, "why": why})
        else:
            if why == "embed unavailable":
                embed_down += 1
            survivors.append(e)
        if i % 50 == 0 or i == len(entries):
            print(f"  [{i}/{len(entries)}] closed={len(closed)} open={len(survivors)}",
                  file=sys.stderr, flush=True)
    if not dry_run and closed:
        rewrite(path, header, survivors)
    return {
        "file": str(path),
        "total": len(entries),
        "closed": len(closed),
        "open": len(survivors),
        "embed_down": embed_down,
        "closed_samples": [c for c in closed[:5]],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--collection", default=os.environ.get("RAG_COLLECTION", "dotfiles"))
    ap.add_argument("--top-k", type=int, default=12)
    ap.add_argument("--legacy", action="store_true",
                    help="also process the legacy rag/rag-gaps.md (rewrites in place)")
    ap.add_argument("--dry-run", action="store_true", help="don't write, just report")
    args = ap.parse_args()

    targets: list[Path] = []
    primary = GAPS_DIR / f"{args.collection}.md"
    if primary.exists():
        targets.append(primary)
    if args.legacy and LEGACY_GAPS.exists():
        targets.append(LEGACY_GAPS)

    if not targets:
        print(f"rag-prune-gaps: no gap file for collection={args.collection!r}", file=sys.stderr)
        print(f"  tried: {primary}" + ("" if not args.legacy else f"\n         {LEGACY_GAPS}"),
              file=sys.stderr)
        return 1

    print(f"rag-prune-gaps: collection={args.collection!r} top_k={args.top_k} "
          f"dry_run={args.dry_run}", file=sys.stderr)

    grand_total = grand_closed = grand_open = grand_embed_down = 0
    for path in targets:
        print(f"\n→ {path.relative_to(RAG_ROOT)}", file=sys.stderr)
        stats = prune_file(path, args.collection, args.top_k, args.dry_run)
        grand_total += stats["total"]
        grand_closed += stats["closed"]
        grand_open += stats["open"]
        grand_embed_down += stats["embed_down"]
        print(f"  total={stats['total']} closed={stats['closed']} open={stats['open']}"
              + (f" embed_down={stats['embed_down']}" if stats["embed_down"] else ""),
              file=sys.stderr)

    if grand_total:
        pct = grand_closed * 100 // grand_total
        action = "would drop" if args.dry_run else "dropped"
        print(f"\nrag-prune-gaps: {action} {grand_closed}/{grand_total} ({pct}%); "
              f"kept {grand_open}" + (f"; embed down for {grand_embed_down}" if grand_embed_down else ""),
              file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
