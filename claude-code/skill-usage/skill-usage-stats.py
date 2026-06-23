#!/usr/bin/env python3
"""Tally Claude Code skill usage from ~/.claude/skill-usage.jsonl.

Collected by hooks/skill-usage-log.sh. Read-only — never modifies anything.

Usage:
    skill-usage-stats.py            # full tally, most-used first
    skill-usage-stats.py --days 30  # only the last N days
"""
import argparse
import json
import os
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone

LOG = os.path.expanduser("~/.claude/skill-usage.jsonl")


def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=0, help="only count the last N days")
    args = ap.parse_args()

    if not os.path.exists(LOG):
        print(f"No usage log yet at {LOG}")
        print("It fills up as skills are invoked (after the hooks are live — restart Claude Code).")
        return

    cutoff = None
    if args.days > 0:
        cutoff = datetime.now(timezone.utc) - timedelta(days=args.days)

    counts = Counter()
    by_event = Counter()
    last_used = {}
    first_seen = None
    total = 0

    with open(LOG, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except Exception:
                continue
            skill = rec.get("skill")
            if not skill:
                continue
            ts = parse_ts(rec.get("ts", ""))
            if cutoff and ts and ts < cutoff:
                continue
            total += 1
            counts[skill] += 1
            by_event[rec.get("event", "?")] += 1
            if ts:
                if skill not in last_used or ts > last_used[skill]:
                    last_used[skill] = ts
                if first_seen is None or ts < first_seen:
                    first_seen = ts

    if total == 0:
        print("No skill invocations recorded yet.")
        return

    scope = f"last {args.days}d" if args.days else "all time"
    since = first_seen.date().isoformat() if first_seen else "?"
    print(f"Skill usage ({scope}): {total} invocations across {len(counts)} skills, since {since}\n")

    width = max((len(s) for s in counts), default=5)
    for skill, n in counts.most_common():
        lu = last_used.get(skill)
        lu_s = lu.date().isoformat() if lu else "?"
        bar = "█" * min(n, 40)
        print(f"  {skill.ljust(width)}  {str(n).rjust(4)}  last {lu_s}  {bar}")

    print(f"\n  by event: {dict(by_event)}")


if __name__ == "__main__":
    main()
