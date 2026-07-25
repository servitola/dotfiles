#!/usr/bin/env python3
"""merge-verified-cases.py — re-verify workflow-generated cases and merge them.

One-shot merge tool. Reads the rag-suite-buildout workflow result, RE-VERIFIES
every candidate case against live retrieval (same path as `rag eval`, via
rag-eval.py helpers — the authoritative gate), dedups against existing cases,
and writes survivors into the per-collection eval files.

Private pattern: per-collection eval files live in dotfiles_private/rag/ and are
symlinked into rag/. New collections get the real file created there + symlink.

Resumable: writes each collection's file as soon as it is processed, and skips
a collection if --only excludes it.
"""
from __future__ import annotations

import importlib.util
import json
import os
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAG_ROOT = HERE.parent
PRIVATE_RAG = Path(os.path.expanduser("~/projects/dotfiles_private/rag"))
ADDED = "2026-06-17"
TOP_K = 12

rag_eval = None


def load_helpers():
    global rag_eval
    spec = importlib.util.spec_from_file_location("rag_eval", str(HERE / "rag-eval.py"))
    rag_eval = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(rag_eval)


def norm(q: str) -> str:
    return re.sub(r"\s+", " ", q.strip().lower())


def eval_paths(collection: str) -> tuple[Path, Path]:
    """Return (real_file, link_in_rag).

    The dotfiles collection's canonical suite is rag/rag.eval.json — a standalone
    real file (not the private-symlink pattern the other collections use).
    """
    if collection == "dotfiles":
        return RAG_ROOT / "rag.eval.json", RAG_ROOT / "rag.eval.json"
    name = f"rag.eval.{collection}.json"
    return PRIVATE_RAG / name, RAG_ROOT / name


def load_existing(collection: str) -> tuple[dict, set]:
    real, link = eval_paths(collection)
    target = link if link.exists() else real
    if target.exists():
        spec = json.loads(target.read_text(encoding="utf-8"))
        existing_q = {norm(c["q"]) for c in spec.get("cases", []) if c.get("q")}
        return spec, existing_q
    spec = {
        "collection": collection,
        "top_k": TOP_K,
        "_comment": f"Regression cases bootstrapped {ADDED}, each verified against live retrieval before insertion.",
        "cases": [],
    }
    return spec, set()


def verify_one(case: dict) -> bool | None:
    vec = rag_eval.embed(case["q"])
    if vec is None:
        return None
    hits = rag_eval.search_then_rerank(case["collection_tmp"], case["q"], vec, TOP_K)
    assertion = {k: case[k] for k in ("must_contain", "must_hit_path") if k in case}
    ok, _ = rag_eval.check_assertion(assertion, hits)
    return bool(ok)


def main() -> int:
    only = None
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))

    out_file = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else None
    if not out_file:
        print("usage: merge-verified-cases.py <workflow-output.json> [--only c1,c2]", file=sys.stderr)
        return 2

    load_helpers()
    PRIVATE_RAG.mkdir(parents=True, exist_ok=True)

    wrapper = json.loads(Path(out_file).read_text(encoding="utf-8"))
    result = wrapper.get("result", wrapper)
    cases_by_coll = result["cases"]

    grand = {"verified": 0, "dupe": 0, "failed": 0, "ratelimit": 0}
    for collection, cands in cases_by_coll.items():
        if only and collection not in only:
            continue
        spec, existing_q = load_existing(collection)
        seen = set(existing_q)
        kept = []
        stats = {"verified": 0, "dupe": 0, "failed": 0, "ratelimit": 0}
        for c in cands:
            q = c.get("q", "")
            atype = c.get("assertion_type")
            aval = c.get("assertion_value", "")
            if not q or atype not in ("must_contain", "must_hit_path") or not aval:
                stats["failed"] += 1
                continue
            nq = norm(q)
            if nq in seen:
                stats["dupe"] += 1
                continue
            case = {"q": q, atype: aval, "collection_tmp": collection}
            verdict = verify_one(case)
            if verdict is None:  # rate-limited; one retry after a pause
                time.sleep(3)
                verdict = verify_one(case)
            if verdict is None:
                stats["ratelimit"] += 1
                continue
            if not verdict:
                stats["failed"] += 1
                continue
            seen.add(nq)
            entry = {"q": q, atype: aval, "auto": True,
                     "origin": c.get("origin", ""), "added": ADDED, "strikes": 0}
            kept.append(entry)
            stats["verified"] += 1

        spec["cases"].extend(kept)
        real, link = eval_paths(collection)
        real.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        if not link.exists():
            if link.is_symlink():
                link.unlink()
            link.symlink_to(real)
            linkinfo = " (new file + symlink)"
        else:
            linkinfo = ""
        for k in grand:
            grand[k] += stats[k]
        print(f"  {collection:20s} kept={stats['verified']:4d}  dupe={stats['dupe']:3d}  "
              f"failed={stats['failed']:3d}  ratelimited={stats['ratelimit']:3d}  "
              f"total_now={len(spec['cases']):4d}{linkinfo}")

    print(f"\nTOTAL kept={grand['verified']} dupe={grand['dupe']} "
          f"failed={grand['failed']} ratelimited={grand['ratelimit']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
