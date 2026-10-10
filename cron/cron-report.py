#!/usr/bin/env python3
"""Compact weekly cron health report as Telegram HTML.

Reuses the cron-calendar parser. Leads with problems (dead/silent/invisible
jobs), then a one-line inventory and the week ahead. Prints to stdout; the
wrapper script pushes it to the "⏱ Cron (Mac)" topic.

Usage: cron/cron-report.py (needs DIR_CRON, DIR_CRON_JOBS)
"""
import importlib.util
from datetime import datetime, timedelta
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("cc", HERE / "cron-calendar.py")
cc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cc)

DEAD_FACTOR = 20        # log older than N × expected interval -> looks dead
DEAD_MIN_DAYS = 3       # never flag anything fresher than this


def main():
    now = datetime.now().replace(second=0, microsecond=0)
    day0 = (now + timedelta(days=1)).replace(hour=0, minute=0)

    jobs, dups_total = [], 0
    for path in cc.collect_fragments():
        topic, cat, summary, js, dups = cc.parse_fragment(path)
        dups_total += sum(dups.values())
        private = path.name.endswith(".private.cron")
        for j in js:
            j.per_day = len(j.fires(day0, day0 + timedelta(days=1)))
            j.private = private
            jobs.append(j)

    dead, nolog, invisible, events7 = [], [], [], 0
    end = now + timedelta(days=7)
    for j in jobs:
        events7 += 0 if j.per_day > cc.FREQUENT_PER_DAY else len(j.fires(now, end))
        if not j.logpath:
            invisible.append(j)
            continue
        if not j.logpath.exists():
            nolog.append(j)
            continue
        mt = datetime.fromtimestamp(j.logpath.stat().st_mtime)
        age = now - mt
        if j.per_day <= 0:
            continue
        expected = timedelta(days=1) / j.per_day
        if age > max(expected * DEAD_FACTOR, timedelta(days=DEAD_MIN_DAYS)):
            dead.append((j, age))

    dead.sort(key=lambda x: -x[1].days)
    L = []
    L.append("<b>⏱ Cron за неделю</b>")

    if dead:
        L.append(f"\n🔴 <b>Похоже, мертвы ({len(dead)})</b> — крутятся, но лог молчит:")
        for j, age in dead[:8]:
            waste = ""
            if j.per_day > 1:
                n = f"{j.per_day * age.days:,}".replace(",", " ")
                waste = f" · ~{n} впустую"
            L.append(f"• <b>{j.fragment}</b> — {j.human}, тишина {age.days}д{waste}")
        if len(dead) > 8:
            L.append(f"  …и ещё {len(dead) - 8}")

    if nolog:
        names = ", ".join(sorted({j.fragment for j in nolog}))
        L.append(f"\n🟡 <b>Лог не создан ({len(nolog)})</b> — ни разу не писали "
                 f"(новые или не запускались): {names}")

    if invisible:
        names = ", ".join(sorted({j.fragment for j in invisible}))
        L.append(f"\n⚪️ <b>Невидимы ({len(invisible)})</b> — не пишут лог, "
                 f"нельзя проверить: {names}")

    if dups_total:
        L.append(f"\n🟠 <b>Дубли строк:</b> {dups_total} — одна и та же задача "
                 f"продублирована в фрагменте")

    if not (dead or nolog or invisible or dups_total):
        L.append("\n✅ Всё чисто — мёртвых и невидимых задач нет")

    priv = sum(1 for j in jobs if j.private)
    bg = sum(1 for j in jobs if j.per_day > cc.FREQUENT_PER_DAY)
    L.append(f"\n📊 <b>Всего:</b> {len(jobs)} задач "
             f"({priv} приватных / {len(jobs) - priv} публичных) · "
             f"{bg} фоновых · {len(jobs) - bg} плановых")
    L.append(f"📅 <b>Неделя вперёд:</b> {events7} плановых запусков")

    nxt = min((j.next_run(now) for j in jobs if j.next_run(now)), default=None)
    if nxt:
        L.append(f"⏭ Ближайшее: {nxt:%d.%m %H:%M}")

    L.append("\n<i>Подробно:</i> <code>cron-cal</code>")
    print("\n".join(L))


if __name__ == "__main__":
    main()
