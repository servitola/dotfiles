#!/usr/bin/env python3
"""Render a static HTML dashboard of every cron job.

Reads the .cron fragments under $DIR_CRON_JOBS (the set cron/install.sh installs),
parses each schedule line, its file header description and log-file status,
computes upcoming runs, and writes a self-contained Gruvbox-Dark-Hard HTML page.

Stdlib only — no croniter, no uv — so it runs from a git pre-commit hook
regardless of PATH. Vixie-cron dom/dow OR semantics are implemented directly.

Usage: cron-calendar.py [--out PATH] [--jobs PATH] [--open]
"""
import argparse
import calendar
import html
import os
import re
from datetime import datetime, timedelta
from pathlib import Path

HOME = Path.home()
CRON_DIR = Path(os.environ["DIR_CRON"])
JOBS_DIR = Path(os.environ["DIR_CRON_JOBS"])
LOG_DIR = CRON_DIR / "logs"
DEFAULT_OUT = CRON_DIR / "cron-calendar.html"

HORIZON_DAYS = 7          # window for the heatmap + agenda
NEXTRUN_HORIZON = 400     # days to look ahead for a single "next run"
FREQUENT_PER_DAY = 6      # more fires/day than this -> collapse in the agenda

FIELD_RANGES = [(0, 59), (0, 23), (1, 31), (1, 12), (0, 7)]
MACROS = {
    "@yearly": "0 0 1 1 *", "@annually": "0 0 1 1 *", "@monthly": "0 0 1 * *",
    "@weekly": "0 0 * * 0", "@daily": "0 0 * * *", "@midnight": "0 0 * * *",
    "@hourly": "0 * * * *",
}
WD = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
MON = ["", "янв", "фев", "мар", "апр", "май", "июн",
       "июл", "авг", "сен", "окт", "ноя", "дек"]


# --------------------------------------------------------------------------- #
# Parsing
# --------------------------------------------------------------------------- #
def expand_field(spec, lo, hi):
    """Expand one cron field (`*`, `*/n`, `a-b`, `a-b/n`, `a,b`, `n`) to a set."""
    out = set()
    for part in spec.split(","):
        step = 1
        if "/" in part:
            part, step_s = part.split("/", 1)
            step = int(step_s)
        if part in ("*", ""):
            start, end = lo, hi
        elif "-" in part:
            a, b = part.split("-", 1)
            start, end = int(a), int(b)
        else:
            start = end = int(part)
        out.update(range(start, end + 1, step))
    return out


class Job:
    def __init__(self, expr, command, inline, fragment, category, description):
        self.expr = expr
        self.command = command
        self.inline = inline
        self.fragment = fragment
        self.category = category
        self.description = description
        f = expr.split()
        self.minutes = expand_field(f[0], 0, 59)
        self.hours = expand_field(f[1], 0, 23)
        self.doms = expand_field(f[2], 1, 31)
        months = expand_field(f[3], 1, 12)
        dows = expand_field(f[4], 0, 7)
        if 7 in dows:
            dows.add(0)
        self.months = months
        self.dows = dows
        self.dom_restricted = f[2] != "*"
        self.dow_restricted = f[4] != "*"
        self.human = describe(f)
        self.logpath = extract_log(command)

    def matches(self, dt):
        if dt.minute not in self.minutes or dt.hour not in self.hours:
            return False
        if dt.month not in self.months:
            return False
        dom_ok = dt.day in self.doms
        dow_ok = dt.weekday_cron in self.dows if hasattr(dt, "weekday_cron") else \
            ((dt.weekday() + 1) % 7) in self.dows
        if self.dom_restricted and self.dow_restricted:
            return dom_ok or dow_ok
        return dom_ok and dow_ok

    def fires(self, start, end, limit=None):
        """All fire datetimes in [start, end); minute-stepped."""
        out = []
        dt = start.replace(second=0, microsecond=0) + timedelta(minutes=1)
        while dt < end:
            if self.matches(dt):
                out.append(dt)
                if limit and len(out) >= limit:
                    break
            dt += timedelta(minutes=1)
        return out

    def next_run(self, now):
        end = now + timedelta(days=NEXTRUN_HORIZON)
        got = self.fires(now, end, limit=1)
        return got[0] if got else None


def describe(f):
    """Human-readable RU schedule from the 5 cron fields (best effort)."""
    mn, hr, dom, mon, dow = f
    everyday = dom == "*" and mon == "*" and dow == "*"
    # --- frequency-style (recurring) ---
    if mn == "*" and hr == "*" and everyday:
        return "каждую минуту"
    if mn.startswith("*/") and hr == "*" and everyday:
        return f"каждые {mn[2:]} мин"
    if "," in mn and hr == "*" and everyday and all(x.isdigit() for x in mn.split(",")):
        vals = sorted(int(x) for x in mn.split(","))
        steps = {b - a for a, b in zip(vals, vals[1:])}
        return f"каждые {steps.pop()} мин" if len(steps) == 1 else f"{len(vals)}×/час"
    if hr.startswith("*/") and everyday and mn.isdigit():
        base = f"каждые {hr[2:]} ч"
        return base if mn == "0" else base + f" в :{int(mn):02d}"
    if hr == "*" and everyday and mn.isdigit():
        return f"ежечасно в :{int(mn):02d}"
    # --- discrete time ---
    time = f"{int(hr):02d}:{int(mn):02d}" if mn.isdigit() and hr.isdigit() else ""
    if dow != "*":
        # cron dow: 0/7=Sun..6=Sat; WD is Mon-indexed -> shift by +6 mod 7
        days = "/".join(dict.fromkeys(WD[(d + 6) % 7] for d in sorted(expand_field(dow, 0, 7))))
        return f"{days} в {time}" if time else days
    if dom.isdigit() and mon.isdigit():
        return f"{int(dom)} {MON[int(mon)]}" + (f" в {time}" if time else "")
    if dom != "*":
        return f"{dom} числа" + (f" в {time}" if time else "")
    if everyday and time:
        return f"ежедневно в {time}"
    return " ".join(f)


def extract_log(command):
    """Pull the redirect target (>>/> path) from a cron command, if any."""
    m = re.search(r'>>?\s*("([^"]+)"|\'([^\']+)\'|(\S+))', command)
    if not m:
        return None
    path = m.group(2) or m.group(3) or m.group(4)
    if path in ("/dev/null", "&1", "2>&1"):
        return None
    path = os.path.expanduser(os.path.expandvars(path))
    return Path(path)


CATEGORY_RULES = [
    ("📱 Телефон", ("phone", "jelly", "battery", "sms", "call", "screentime",
                    "presence", "voicenotes", "morning", "notification")),
    ("⏰ Напоминания", ("reminder",)),
    ("📰 Фиды/дайджесты", ("feed", "youtrack", "digest")),
    ("🧠 RAG", ("rag",)),
    ("🔎 Insights", ("insight",)),
    ("💼 Работа", ("work-snapshot",)),
    ("🔧 Обслуживание", ("tmux", "reaper", "dep-bump", "prune")),
]


def categorize(topic):
    low = topic.lower()
    for name, keys in CATEGORY_RULES:
        if any(k in low for k in keys):
            return name
    return "🗂 Прочее"


def header_summary(lines):
    """First meaningful sentence from a fragment's leading comment block."""
    text = []
    for ln in lines:
        s = ln.strip()
        if not s.startswith("#"):
            break
        s = s.lstrip("#").strip().strip("=").strip()
        if s and "Managed by dotfiles" not in s and "Crontab" not in s:
            text.append(s)
        if len(text) >= 2:
            break
    return " ".join(text)[:220]


CRON_LINE = re.compile(r'^\s*(@\w+|[\d*/,\-]+(?:\s+[\d*/,\-]+){4})\s+(.*)$')


def parse_fragment(path):
    topic = path.name.replace(".private.cron", "").replace(".cron", "")
    category = categorize(topic)
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    summary = header_summary(lines)
    jobs, seen, dups = [], {}, {}
    for ln in lines:
        if not ln.strip() or ln.strip().startswith("#"):
            continue
        m = CRON_LINE.match(ln)
        if not m:
            continue
        sched, rest = m.group(1), m.group(2)
        if sched.startswith("@"):
            if sched not in MACROS:
                continue
            sched = MACROS[sched]
        command, inline = rest, ""
        cm = re.search(r'\s+#\s*(.+)$', rest)
        if cm and '"' not in rest[cm.start():] and "'" not in rest[cm.start():]:
            command, inline = rest[:cm.start()].rstrip(), cm.group(1)
        key = f"{sched}|{command}"
        seen[key] = seen.get(key, 0) + 1
        if seen[key] > 1:
            dups[key] = seen[key]
            continue
        jobs.append(Job(sched, command, inline, topic, category, summary))
    return topic, category, summary, jobs, dups


def collect_fragments():
    return sorted(JOBS_DIR.rglob("*.cron"), key=lambda p: p.name)


def configure_sources(jobs_dir):
    global JOBS_DIR
    JOBS_DIR = jobs_dir


# --------------------------------------------------------------------------- #
# Rendering
# --------------------------------------------------------------------------- #
GRUV = dict(bg0="#1d2021", bg1="#282828", bg2="#3c3836", bg3="#504945",
            fg="#ebdbb2", fg4="#a89984", gray="#928374", red="#fb4934",
            green="#b8bb26", yellow="#fabd2f", blue="#83a598", purple="#d3869b",
            aqua="#8ec07c", orange="#fe8019")


def esc(s):
    return html.escape(str(s))


def log_status(job, now):
    p = job.logpath
    if not p:
        return ("—", "gray", "")
    if not p.exists():
        return ("нет лога", "orange", str(p))
    mt = datetime.fromtimestamp(p.stat().st_mtime)
    age = now - mt
    size = p.stat().st_size
    if age < timedelta(hours=1):
        txt = "только что"
    elif age < timedelta(days=1):
        txt = f"{int(age.total_seconds() // 3600)}ч назад"
    else:
        txt = f"{age.days}д назад"
    color = "green" if age < timedelta(days=2) else ("yellow" if age < timedelta(days=7) else "red")
    return (f"{txt} · {size // 1024 or 1}K", color, f"{p} — {mt:%Y-%m-%d %H:%M}")


def build(now):
    frags = collect_fragments()
    parsed = [parse_fragment(p) for p in frags]
    all_jobs = [j for _, _, _, jobs, _ in parsed for j in jobs]

    # Classify: a job that fires more than FREQUENT_PER_DAY times on a full day
    # is a "background" poller (shown once); the rest are dated "events".
    day0 = (now + timedelta(days=1)).replace(hour=0, minute=0)
    for j in all_jobs:
        j.per_day = len(j.fires(day0, day0 + timedelta(days=1)))
        j.background = j.per_day > FREQUENT_PER_DAY
    background = sorted((j for j in all_jobs if j.background),
                        key=lambda j: -j.per_day)
    events = [j for j in all_jobs if not j.background]

    # Heatmap + agenda are built from EVENTS only, so real peaks stay visible.
    end = now + timedelta(days=HORIZON_DAYS)
    heat = [[0] * 24 for _ in range(7)]
    per_day = {}   # date -> list[(dt, job)]
    for j in events:
        for dt in j.fires(now, end):
            heat[dt.weekday()][dt.hour] += 1
            per_day.setdefault(dt.date(), []).append((dt, j))

    anomalies = []
    for topic, _, _, jobs, dups in parsed:
        for cnt in dups.values():
            anomalies.append(("dup", topic, f"дублированная строка ×{cnt}"))
        for j in jobs:
            nr = j.next_run(now)
            if nr is None and j.expr.split()[2] != "*" and j.expr.split()[3] != "*":
                anomalies.append(("past", topic, f"one-shot в прошлом (не самочистится): {j.human}"))
            st, color, _ = log_status(j, now)
            if color == "red" and j.background:
                anomalies.append(("silent", topic, f"фоновая задача, лог молчит ({st})"))

    return parsed, all_jobs, background, events, heat, per_day, anomalies


def render(now, parsed, all_jobs, background, events, heat, per_day, anomalies):
    g = GRUV
    hottest = max((c for row in heat for c in row), default=1) or 1

    def cell(v):
        if v == 0:
            return f'background:{g["bg2"]}'
        a = 0.22 + 0.78 * (v / hottest)
        return f'background:rgba(131,165,152,{a:.2f})'   # blue-ish for events

    # heatmap (events only)
    heat_rows = ['<tr><th></th>' + "".join(
        f'<th>{h:02d}</th>' for h in range(24)) + '</tr>']
    for d in range(7):
        cells = "".join(
            f'<td style="{cell(heat[d][h])}" title="{WD[d]} {h:02d}:00 — {heat[d][h]} событий"></td>'
            for h in range(24))
        heat_rows.append(f'<tr><th>{WD[d]}</th>{cells}</tr>')
    heat_html = "\n".join(heat_rows)

    # background pollers, grouped by category, shown once
    bg_cats = {}
    for j in background:
        bg_cats.setdefault(j.category, []).append(j)
    bg_blocks = []
    for category in sorted(bg_cats):
        rows = []
        for j in sorted(bg_cats[category], key=lambda x: -x.per_day):
            st, color, tip = log_status(j, now)
            rows.append(
                f'<div class="brow"><span class="chip">{esc(j.human)}</span>'
                f'<span class="bname">{esc(j.fragment)}</span>'
                f'<span class="bstat"><span class="dot {color}" title="{esc(tip)}"></span>'
                f'{esc(st)}</span></div>')
        bg_blocks.append(
            f'<div class="bgroup"><div class="ghead">{esc(category)} '
            f'<span class="cnt">{len(rows)}</span></div>{"".join(rows)}</div>')
    bg_html = "".join(bg_blocks) or '<div class="empty">— нет фоновых задач —</div>'

    # agenda (events only)
    agenda = []
    for i in range(HORIZON_DAYS):
        day = (now + timedelta(days=i)).date()
        items = sorted(per_day.get(day, []), key=lambda x: x[0])
        label = {0: "Сегодня", 1: "Завтра"}.get(i, f"{WD[day.weekday()]}, {day.day} {MON[day.month]}")
        rows = []
        for dt, j in items:
            rows.append(
                f'<div class="arow"><span class="t">{dt:%H:%M}</span>'
                f'<span class="al"><b>{esc(j.fragment)}</b> '
                f'<span class="cat">{esc(j.category)}</span></span></div>')
        body = "\n".join(rows) if rows else '<div class="empty">— тихо —</div>'
        agenda.append(f'<div class="day"><h3>{esc(label)}'
                      f'<span class="cnt">{len(items)}</span></h3>{body}</div>')
    agenda_html = "\n".join(agenda)

    # full reference: by-category / by-file list
    cats = {}
    for topic, category, summary, jobs, _ in parsed:
        cats.setdefault(category, []).append((topic, summary, jobs))
    blocks = []
    for category in sorted(cats):
        files = sorted(cats[category])
        filerows = []
        for topic, summary, jobs in files:
            jrows = []
            for j in jobs:
                st, color, tip = log_status(j, now)
                nr = j.next_run(now)
                nrtxt = f"{nr:%d %b %H:%M}" if nr else "—"
                tag = '<span class="bg-tag">фон</span>' if j.background else ""
                jrows.append(
                    f'<tr><td class="hum">{esc(j.human)}{tag}<br>'
                    f'<code>{esc(j.expr)}</code></td>'
                    f'<td class="next">{esc(nrtxt)}</td>'
                    f'<td class="lg"><span class="dot {color}" title="{esc(tip)}"></span>{esc(st)}</td>'
                    f'<td class="cmd"><code>{esc(j.command[:90])}</code>'
                    f'{f"<span class=inl>› {esc(j.inline)}</span>" if j.inline else ""}</td></tr>')
            filerows.append(
                f'<div class="file"><div class="fhead"><b>{esc(topic)}</b>'
                f'<span class="fsum">{esc(summary)}</span></div>'
                f'<table class="jobs">{"".join(jrows)}</table></div>')
        blocks.append(f'<section><h2>{esc(category)} '
                      f'<span class="cnt">{sum(len(j) for _,_,j in files)}</span></h2>'
                      f'{"".join(filerows)}</section>')
    list_html = "\n".join(blocks)

    # anomalies
    labels = {"dup": "дубль", "past": "просрочено", "silent": "молчит"}
    if anomalies:
        arows = "".join(
            f'<li><span class="atag {kind}">{esc(labels.get(kind, kind))}</span> '
            f'<b>{esc(topic)}</b> — {esc(msg)}</li>'
            for kind, topic, msg in anomalies)
        anom_html = f'<ul class="anom">{arows}</ul>'
    else:
        anom_html = '<p class="ok">✓ аномалий не найдено</p>'

    ev7 = sum(len(v) for v in per_day.values())
    nxt = min((dt for v in per_day.values() for dt, _ in v), default=None)
    nxt_txt = f"{nxt:%H:%M · %d %b}" if nxt else "—"

    return f"""<!doctype html><html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cron календарь</title><style>
:root{{color-scheme:dark}}
*{{box-sizing:border-box}}
body{{margin:0;min-height:100vh;color:{g['fg']};
background:radial-gradient(1100px 600px at 12% -8%,rgba(184,187,38,.10),transparent 60%),
radial-gradient(1050px 640px at 100% 2%,rgba(254,128,25,.09),transparent 55%),
radial-gradient(950px 760px at 50% 120%,rgba(131,165,152,.11),transparent 60%),{g['bg0']};
background-attachment:fixed;
font:14px/1.5 -apple-system,BlinkMacSystemFont,"SF Pro Text",Segoe UI,Roboto,
"Apple Color Emoji","Segoe UI Emoji",sans-serif}}
code{{font-family:"SF Mono",ui-monospace,Menlo,monospace;font-size:12px;color:{g['aqua']}}}
.wrap{{max-width:1180px;margin:0 auto;padding:32px 20px 90px}}
h1{{margin:0 0 4px;font-size:24px;letter-spacing:-.02em}}
.sub{{color:{g['gray']};margin:0 0 26px;font-size:13px}}
/* frosted glass panels — Apple-glass Gruvbox */
.stat,.bgroup,.day,.file,.anom li{{
background:rgba(60,56,54,.34);
-webkit-backdrop-filter:blur(20px) saturate(170%);backdrop-filter:blur(20px) saturate(170%);
border:1px solid rgba(235,219,178,.10);border-radius:16px;
box-shadow:0 6px 26px rgba(0,0,0,.34),inset 0 1px 0 rgba(235,219,178,.09)}}
.stats{{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:30px}}
.stat{{padding:14px 20px;min-width:120px}}
.stat b{{display:block;font-size:26px;color:{g['yellow']};letter-spacing:-.01em}}
.stat span{{color:{g['gray']};font-size:12px}}
h2{{font-size:17px;margin:38px 0 12px;padding-bottom:7px;
border-bottom:1px solid rgba(235,219,178,.10)}}
.cnt{{background:rgba(235,219,178,.10);color:{g['fg4']};font-size:12px;border-radius:10px;
padding:1px 9px;margin-left:6px;vertical-align:middle}}
table.heat{{border-collapse:separate;border-spacing:3px;width:100%}}
table.heat th{{color:{g['gray']};font-weight:500;font-size:11px;padding:2px}}
table.heat td{{width:3.6%;height:20px;border-radius:5px}}
table.heat th:first-child{{width:34px;text-align:right;padding-right:8px}}
.legend{{color:{g['gray']};font-size:12px;margin-top:8px}}
.bg{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}}
.bgroup{{padding:14px 16px}}
.ghead{{font-size:14px;font-weight:600;margin-bottom:8px}}
.brow{{display:flex;align-items:center;gap:8px;padding:5px 0;
border-top:1px solid rgba(235,219,178,.07);font-size:13px}}
.brow:nth-of-type(2){{border-top:none}}
.bname{{font-weight:600;flex:1}}
.bstat{{color:{g['gray']};font-size:12px;white-space:nowrap}}
.agenda{{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:14px}}
.day{{padding:14px 16px}}
.day h3{{margin:0 0 8px;font-size:14px;display:flex;justify-content:space-between;align-items:center}}
.arow{{display:flex;gap:10px;align-items:baseline;padding:6px 0;
border-top:1px solid rgba(235,219,178,.07)}}
.arow:first-of-type{{border-top:none}}
.al b{{font-weight:600}}
.t{{background:linear-gradient(180deg,rgba(131,165,152,.95),rgba(131,165,152,.72));
color:{g['bg0']};border-radius:7px;padding:2px 8px;font-size:12px;font-weight:700;
font-variant-numeric:tabular-nums;box-shadow:0 1px 5px rgba(0,0,0,.28)}}
.chip{{background:rgba(235,219,178,.10);color:{g['aqua']};border-radius:7px;padding:2px 9px;
font-size:11px;white-space:nowrap;font-variant-numeric:tabular-nums;
border:1px solid rgba(235,219,178,.09)}}
.cat{{color:{g['gray']};font-size:11px}}
.bg-tag{{background:rgba(235,219,178,.08);color:{g['gray']};font-size:9px;border-radius:5px;
padding:1px 5px;margin-left:6px;text-transform:uppercase;vertical-align:middle}}
.empty{{color:{g['gray']};font-size:12px;padding:5px 0}}
.file{{padding:12px 16px;margin-bottom:12px}}
.fhead{{display:flex;gap:10px;align-items:baseline;flex-wrap:wrap;margin-bottom:6px}}
.fsum{{color:{g['gray']};font-size:12px}}
table.jobs{{width:100%;border-collapse:collapse}}
table.jobs td{{padding:6px 8px;border-top:1px solid rgba(235,219,178,.07);
vertical-align:top;font-size:13px}}
.hum{{white-space:nowrap}}
.next{{color:{g['blue']};white-space:nowrap}}
.cmd{{width:46%}}
.inl{{color:{g['purple']};font-size:11px;margin-left:6px}}
.dot{{display:inline-block;width:8px;height:8px;border-radius:50%;margin-right:6px;
box-shadow:0 0 7px currentColor}}
.dot.green{{background:{g['green']};color:{g['green']}}}.dot.yellow{{background:{g['yellow']};color:{g['yellow']}}}
.dot.red{{background:{g['red']};color:{g['red']}}}.dot.orange{{background:{g['orange']};color:{g['orange']}}}
.dot.gray{{background:{g['gray']};color:{g['gray']}}}
.anom{{list-style:none;padding:0;margin:0}}
.anom li{{padding:9px 13px;margin-bottom:7px;font-size:13px}}
.atag{{font-size:11px;border-radius:5px;padding:1px 6px;margin-right:6px;text-transform:uppercase}}
.atag.dup{{background:{g['orange']};color:{g['bg0']}}}
.atag.past{{background:{g['red']};color:{g['bg0']}}}
.atag.silent{{background:{g['yellow']};color:{g['bg0']}}}
.ok{{color:{g['green']}}}
</style></head><body><div class="wrap">
<h1>🗓 Cron календарь</h1>
<p class="sub">Сгенерировано {now:%Y-%m-%d %H:%M} · источник: cron_jobs/</p>
<div class="stats">
<div class="stat"><b>{len(all_jobs)}</b><span>всего задач</span></div>
<div class="stat"><b>{len(background)}</b><span>фоновых (крутятся)</span></div>
<div class="stat"><b>{len(events)}</b><span>плановых</span></div>
<div class="stat"><b>{esc(nxt_txt)}</b><span>ближайшее событие</span></div>
<div class="stat"><b>{len(anomalies)}</b><span>аномалий</span></div>
</div>

<h2>🔁 Фоновые задачи <span class="cnt">{len(background)}</span></h2>
<div class="legend">крутятся постоянно по интервалу — показаны один раз, не в календаре ниже</div>
<div class="bg">{bg_html}</div>

<h2>📅 Плановые события · неделя <span class="cnt">{ev7}</span></h2>
<div class="legend">строки — дни, столбцы — часы (00–23); ярче = больше плановых событий в этот час</div>
<table class="heat">{heat_html}</table>

<h2>Ближайшие 7 дней</h2>
<div class="agenda">{agenda_html}</div>

<h2>⚠️ Аномалии <span class="cnt">{len(anomalies)}</span></h2>
{anom_html}

<h2>📖 Все задачи по категориям <span class="cnt">{len(all_jobs)}</span></h2>
{list_html}
</div></body></html>"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--jobs", type=Path, default=JOBS_DIR)
    ap.add_argument("--open", action="store_true")
    args = ap.parse_args()
    configure_sources(args.jobs)
    now = datetime.now().replace(second=0, microsecond=0)
    parsed, all_jobs, background, events, heat, per_day, anomalies = build(now)
    out = render(now, parsed, all_jobs, background, events, heat, per_day, anomalies)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(out, encoding="utf-8")
    print(f"✓ cron calendar → {args.out} ({len(all_jobs)} jobs, {len(anomalies)} anomalies)")
    if args.open:
        import subprocess
        subprocess.run(["open", str(args.out)], check=False)


if __name__ == "__main__":
    main()
