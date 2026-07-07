#!/usr/bin/env python3
"""rag-answer-eval-nightly.py — scheduled answer-quality gate with regression alert.

Wraps `rag answer-eval` (rag-answer-eval.py): runs it with a SMALL sample for a
rotation of collections, then compares each collection's fresh quality score
against the previous run's score and raises ONE concise Telegram alert if any
collection regressed.

Why a rotation, not all 10 every night
---------------------------------------
All 10 collections × 8 cases × 2 chat calls = ~160 chat calls/night, which
collides with the hourly rag-improve quota on free-tier / reasoning models.
So we split the 10 collections into two halves and run ONE half per night,
keyed off the day-of-year parity. Each collection is therefore graded every
other night — frequent enough to catch a real regression, light enough to live
beside rag-improve. Override with --collections "a,b,c" or --all.

Regression rules (per collection, evaluated only when there IS signal)
----------------------------------------------------------------------
  * DROP   — score fell by more than --drop-threshold percentage points vs the
             previous recorded score for that collection.
  * FLOOR  — score is below --floor (absolute), regardless of history.
A collection with NO previous score can still trip FLOOR but never DROP.

Fail-safe (no false alarms on a transport/model hiccup)
-------------------------------------------------------
Each per-collection run is "no signal" — skipped from the regression check and
NOT written as a new baseline — when:
  * the underlying `rag answer-eval` exits non-zero, or
  * fewer than half the sampled cases were actually graded (SKIP-heavy: model
    or embed transport was flaky).
A no-signal run still appends its normal history block (answer-eval does that
itself); it just doesn't move the baseline or fire an alert.

State
-----
Previous scores live in a tiny JSON state file (default
rag-answer-eval-state.json next to the history). Only signal-bearing runs
update it. The Markdown history is the human log; the state file is the machine
baseline.

Usage:
  rag-answer-eval-nightly.py                  # tonight's rotation half
  rag-answer-eval-nightly.py --all            # every collection
  rag-answer-eval-nightly.py --collections dotfiles,serho
  rag-answer-eval-nightly.py --sample 8
  rag-answer-eval-nightly.py --dry-run        # print the alert, do NOT send
  rag-answer-eval-nightly.py --force-score 10 # inject a fake score (testing the alert path)

Exit code is always 0 (this is a report + alert, never a hard gate) unless its
own inputs are unusable.
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAG_ROOT = HERE.parent
EVAL_TOOL = HERE / "rag-answer-eval.py"
STATE_FILE = RAG_ROOT / "rag-answer-eval-state.json"
TG_SEND = Path.home() / "projects/dotfiles/cron/scripts/tg-send-thread.sh"
# Owned by this script (not the cron line) so the lock is a real os.mkdir
# syscall, immune to the user's interactive `mkdir -pv` alias which would make a
# shell-level mkdir lock silently no-op. Mirrors rag-improve's single-run rule.
LOCK_DIR = Path("/tmp/rag-answer-eval-nightly.lock")

# (collection, eval-file-relative-to-RAG_ROOT). dotfiles uses the unsuffixed
# file; the rest follow rag.eval.<collection>.json (symlinks into dotfiles_private).
COLLECTIONS = [
    ("dotfiles", "rag.eval.json"),
    ("services", "rag.eval.services.json"),
    ("serho", "rag.eval.serho.json"),
    ("sphere", "rag.eval.sphere.json"),
    ("glasswings", "rag.eval.glasswings.json"),
    ("workbot2", "rag.eval.workbot2.json"),
    ("spotwarevpn", "rag.eval.spotwarevpn.json"),
    ("spotware-dev-docs", "rag.eval.spotware-dev-docs.json"),
    ("spotware-code", "rag.eval.spotware-code.json"),
    ("spotware-docs", "rag.eval.spotware-docs.json"),
]

# Telegram target. Defaults to servitola's serho group + morning-digest topic;
# override the thread with RAG_EVAL_TG_THREAD (e.g. a dedicated monitoring topic).
TG_CHAT = os.environ.get("RAG_EVAL_TG_CHAT", "-1003172923198")
TG_THREAD = os.environ.get("RAG_EVAL_TG_THREAD", "50779")


def load_state() -> dict:
    if STATE_FILE.is_file():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n",
                          encoding="utf-8")


def rotation_for_today(half: int | None = None) -> list[tuple[str, str]]:
    """Return tonight's half of COLLECTIONS (even/odd day-of-year)."""
    if half is None:
        half = datetime.date.today().timetuple().tm_yday % 2
    return [c for i, c in enumerate(COLLECTIONS) if i % 2 == half]


def parse_run_output(text: str) -> tuple[float | None, int, int]:
    """Parse a `rag answer-eval` stdout. Returns (score, graded, sampled)."""
    score = None
    graded = 0
    m = re.search(r"quality score:\s*([0-9]+(?:\.[0-9]+)?)%.*?over\s+(\d+)\s+graded",
                  text)
    if m:
        score = float(m.group(1))
        graded = int(m.group(2))
    # "grading N cases" appears on stderr (we capture both streams together).
    sm = re.search(r"grading\s+(\d+)\s+cases", text)
    sampled = int(sm.group(1)) if sm else 0
    return score, graded, sampled


def run_collection(coll: str, eval_file: Path, sample: int,
                   answer_model: str, judge_model: str) -> dict:
    """Run answer-eval for one collection. Returns a result dict."""
    cmd = [
        sys.executable, str(EVAL_TOOL),
        "--eval-file", str(eval_file),
        "--sample", str(sample),
        "--answer-model", answer_model,
        "--judge-model", judge_model,
        # Deterministic-per-night sample so a regression isn't sampling noise.
        "--seed", f"nightly-{coll}-{datetime.date.today():%Y-%m-%d}",
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=3600)
    except Exception as e:
        return {"collection": coll, "ok": False, "signal": False,
                "score": None, "graded": 0, "sampled": 0,
                "note": f"run failed: {e}"}
    out = (proc.stdout or "") + "\n" + (proc.stderr or "")
    score, graded, sampled = parse_run_output(out)
    ok = proc.returncode == 0
    # Signal = clean exit, a parsed score, and at least half the sample graded.
    signal = bool(ok and score is not None and sampled > 0
                  and graded >= max(1, sampled // 2))
    note = ""
    if not ok:
        note = f"exit {proc.returncode}"
    elif score is None:
        note = "no score parsed"
    elif not signal:
        note = f"SKIP-heavy ({graded}/{sampled} graded) — no signal"
    return {"collection": coll, "ok": ok, "signal": signal,
            "score": score, "graded": graded, "sampled": sampled, "note": note,
            "stdout": proc.stdout or ""}


def build_alert(regressions: list[dict]) -> str:
    lines = ["⚠️ RAG answer-eval regression"]
    for r in regressions:
        prev = r.get("prev")
        prev_s = f"{prev:.0f}%" if prev is not None else "n/a"
        reasons = []
        if r.get("drop"):
            reasons.append(f"drop {prev_s}→{r['score']:.0f}%")
        if r.get("floor"):
            reasons.append(f"below floor ({r['score']:.0f}%)")
        lines.append(f"• {r['collection']}: {', '.join(reasons)} "
                     f"({r['graded']} graded)")
    return "\n".join(lines)


def send_telegram(text: str, dry_run: bool) -> None:
    if dry_run:
        print("--- DRY RUN: would send Telegram alert ---")
        print(f"  chat={TG_CHAT} thread={TG_THREAD}")
        print(f"  via {TG_SEND}")
        for line in text.splitlines():
            print(f"  | {line}")
        print("--- (no message sent) ---")
        return
    subprocess.run([str(TG_SEND), TG_CHAT, TG_THREAD, text], check=False)


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sample", type=int, default=8,
                    help="cases per collection (default 8)")
    # Match the tool's defaults (A/B-chosen): a reliable non-reasoning judge and
    # the answer model `rag ask` actually serves. `fast/fast` was a broken grader
    # (leaks <think>, self-grades, rate-limit SKIPs) → noisy low scores that look
    # like "quality regressed" when only the gauge was miscalibrated.
    ap.add_argument("--answer-model", default=os.environ.get("RAG_ANSWER_MODEL", "gpt"))
    ap.add_argument("--judge-model", default=os.environ.get("RAG_JUDGE_MODEL", "github-gpt4o-mini"))
    ap.add_argument("--collections", default="",
                    help="comma list to override tonight's rotation")
    ap.add_argument("--all", action="store_true", help="run every collection")
    ap.add_argument("--half", type=int, choices=(0, 1), default=None,
                    help="force rotation half (else day-of-year parity)")
    ap.add_argument("--drop-threshold", type=float, default=15.0,
                    help="alert if score drops more than this many pp (default 15)")
    ap.add_argument("--floor", type=float, default=50.0,
                    help="alert if score is below this absolute %% (default 50)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the alert instead of sending it")
    ap.add_argument("--force-score", type=float, default=None,
                    help="TEST ONLY: override every parsed score with this value")
    args = ap.parse_args()

    if not EVAL_TOOL.is_file():
        print(f"nightly: eval tool missing: {EVAL_TOOL}", file=sys.stderr)
        return 1

    # Single-run lock (atomic os.mkdir). Skip cleanly if another run holds it.
    # --dry-run / --force-score are interactive testing and don't take the lock.
    holding_lock = False
    if not (args.dry_run or args.force_score is not None):
        try:
            os.mkdir(LOCK_DIR)
            holding_lock = True
        except FileExistsError:
            print(f"nightly: another run holds {LOCK_DIR}, exiting",
                  file=sys.stderr)
            return 0

    try:
        return _run(args)
    finally:
        if holding_lock:
            try:
                LOCK_DIR.rmdir()
            except OSError:
                pass


def _run(args) -> int:
    # Resolve which collections to run.
    if args.collections:
        wanted = {c.strip() for c in args.collections.split(",") if c.strip()}
        todo = [c for c in COLLECTIONS if c[0] in wanted]
        missing = wanted - {c[0] for c in COLLECTIONS}
        if missing:
            print(f"nightly: unknown collection(s): {', '.join(sorted(missing))}",
                  file=sys.stderr)
    elif args.all:
        todo = list(COLLECTIONS)
    else:
        todo = rotation_for_today(args.half)

    if not todo:
        print("nightly: nothing to run", file=sys.stderr)
        return 1

    state = load_state()
    results = []
    print(f"nightly: {datetime.datetime.now():%Y-%m-%d %H:%M} — running "
          f"{len(todo)} collection(s): {', '.join(c for c, _ in todo)}",
          file=sys.stderr)

    for coll, fname in todo:
        eval_file = RAG_ROOT / fname
        if not eval_file.exists():
            print(f"  {coll}: eval file missing ({eval_file}), skipping",
                  file=sys.stderr)
            results.append({"collection": coll, "ok": False, "signal": False,
                            "score": None, "graded": 0, "sampled": 0,
                            "note": "eval file missing"})
            continue
        r = run_collection(coll, eval_file, args.sample,
                           args.answer_model, args.judge_model)
        if args.force_score is not None:
            # Testing hook: pretend the run produced this score, keep signal flag
            # if the run was otherwise healthy so the alert path can be exercised.
            r["score"] = args.force_score
            if r["ok"]:
                r["signal"] = True
                r["graded"] = r["graded"] or args.sample
                r["note"] = f"forced score {args.force_score}"
        results.append(r)
        flag = "signal" if r["signal"] else f"no-signal ({r['note']})"
        sc = f"{r['score']:.0f}%" if r["score"] is not None else "—"
        print(f"  {coll}: {sc} [{flag}]", file=sys.stderr)

    # Regression check — only signal-bearing runs.
    regressions = []
    for r in results:
        if not r["signal"]:
            continue
        coll = r["collection"]
        score = r["score"]
        prev = state.get(coll, {}).get("score")
        drop = prev is not None and (prev - score) > args.drop_threshold
        floor = score < args.floor
        if drop or floor:
            regressions.append({**r, "prev": prev, "drop": drop, "floor": floor})
        # Move the baseline forward on every signal-bearing run.
        state[coll] = {
            "score": score,
            "graded": r["graded"],
            "ts": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        }

    save_state(state)

    if regressions:
        alert = build_alert(regressions)
        print("\n" + alert)
        send_telegram(alert, args.dry_run)
    else:
        signal_n = sum(1 for r in results if r["signal"])
        print(f"\nnightly: no regression "
              f"({signal_n}/{len(results)} signal-bearing runs)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
