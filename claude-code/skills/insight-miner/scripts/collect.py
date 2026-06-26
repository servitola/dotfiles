#!/usr/bin/env python3
"""insight-miner collector — read-only, 0 LLM.

Modes:
  collect.py scan   [--days N]   incremental capture (mtime>watermark) -> events.jsonl
  collect.py report [--days N]    aggregate window -> report.json + human digest (stdout)
  collect.py tg     [--days N]    compact one-message digest for Telegram (stdout)

Signals: repeated non-plumbing command sigs (alias/script), tool error classes,
permission prompts (-> /fewer-permission-prompts), your corrections (from history.jsonl).
Scope tags ATTRIBUTION only: own/work = you; serho = friends+bot -> improve the platform.
No content firewall (serho topics are public friend Q&A the user wants mined).
"""
import json, os, re, sys, glob, time, shlex
from collections import Counter, defaultdict

PROJ = os.path.expanduser("~/.claude/projects")
HIST = os.path.expanduser("~/.claude/history.jsonl")
STATE = os.path.expanduser("~/.local/state/insight-miner")
EVENTS = os.path.join(STATE, "events.jsonl")
WM = os.path.join(STATE, "watermark")
REPORT = os.path.join(STATE, "report.json")
LEDGER = os.path.expanduser("~/projects/dotfiles/claude-code-memory/insights.md")
EVENT_RETENTION_D = 30

SERHO = ("gokar", "serho-users", "serho", "Renata-bot", "Renata", "Marina",
         "mama-telegram-bot", "mama")
def scope_of(cwd):
    c = cwd or ""
    if any(k in c for k in SERHO): return "serho"
    if "Spotware" in c: return "work"
    return "own"

PLUMBING = {"cd","ls","echo","cat","grep","rg","find","sleep","source","export",
            "set","mkdir","rm","head","tail","wc","sed","awk","pwd","true","test",
            "[","printf","touch","chmod","tee","cut","sort","uniq","xargs","jq",
            "for","while","if","then","do","cp","mv","which","kill","ps","date"}
CORR = re.compile(r"\b(нет,|не туда|не надо|не так|неправильно|не то|стоп,|"
                  r"instead|actually|на самом деле|don't|do not|wrong|revert|"
                  r"откати|верни обратно|не нужно|зачем ты)\b", re.I)
NOISE_PFX = ("base directory for this skill", "this session is being continued",
             "<", "[pasted", "[image")

def _san(t):
    if "/" in t: return "<path>"
    if re.search(r"[=\"'$`]", t): return "<arg>"
    if re.fullmatch(r"[A-Z0-9]{8,}", t): return "<id>"
    return t

def cmd_sig(cmd):
    line = cmd.strip().split("\n")[0]
    try: toks = shlex.split(line)
    except Exception: toks = line.split()
    i = 0
    while i < len(toks) and (re.match(r"^\w+=", toks[i]) or
                             toks[i] in ("sudo","command","exec","time","env")):
        i += 1
    rest = toks[i:]
    if not rest or "/" in rest[0] or "=" in rest[0]: return None
    return " ".join([rest[0]] + [_san(t) for t in rest[1:3]])

def err_class(text):
    t = (text or "").strip(); first = t.split("\n")[0][:90]; low = t.lower()
    m = re.search(r"permission to use \w+ with command (\S+)", low)
    if m: return "PERM " + m.group(1)
    if "string to replace not found" in low: return "Edit: string not found (stale read)"
    if "refusing to write through symlink" in low: return "Edit: write through symlink"
    if "file does not exist" in low: return "Read: file does not exist (wrong cwd?)"
    if "eisdir" in low: return "Read on a directory (EISDIR)"
    if "command not found" in low or "not found" in first.lower(): return "command/file not found"
    if "no such file" in low: return "no such file or directory"
    if "permission denied" in low: return "permission denied (fs)"
    m = re.search(r"exit code (\d+)", low)
    if m: return f"exit code {m.group(1)}"
    if "timed out" in low or "timeout" in low: return "timeout"
    if "<tool_use_error>" in low: return "tool_use_error (generic)"
    return re.sub(r"\s+", " ", first)[:48]

def text_of(content):
    if isinstance(content, str): return content
    if isinstance(content, list):
        return " ".join(b.get("text","") for b in content
                        if isinstance(b, dict) and b.get("type") == "text")
    return ""

# ---------------- scan (incremental capture) ----------------
def scan(days):
    os.makedirs(STATE, exist_ok=True)
    now = time.time()
    if days is not None: cutoff = now - days * 86400
    else:
        try: cutoff = float(open(WM).read().strip())
        except Exception: cutoff = now - 7 * 86400
    # (scope, kind, sig, proj) -> count
    agg = Counter()
    for f in glob.glob(os.path.join(PROJ, "**", "*.jsonl"), recursive=True):
        if os.path.getmtime(f) < cutoff: continue
        cwd = ""; acted = False
        try:
            for line in open(f, encoding="utf-8"):
                line = line.strip()
                if not line: continue
                try: r = json.loads(line)
                except Exception: continue
                cwd = r.get("cwd") or cwd; sc = scope_of(cwd)
                typ = r.get("type"); content = (r.get("message") or {}).get("content")
                if typ == "assistant" and isinstance(content, list):
                    for b in content:
                        if isinstance(b, dict) and b.get("type") == "tool_use":
                            acted = True
                            if b.get("name") == "Bash":
                                s = cmd_sig((b.get("input") or {}).get("command",""))
                                if s: agg[(sc,"cmd",s,cwd)] += 1
                elif typ == "user" and isinstance(content, list):
                    for b in content:
                        if isinstance(b, dict) and b.get("type")=="tool_result" and b.get("is_error"):
                            p = b.get("content")
                            txt = p if isinstance(p,str) else (p[0].get("text","") if isinstance(p,list) and p and isinstance(p[0],dict) else "")
                            ec = err_class(txt)
                            kind = "perm" if ec.startswith("PERM ") else "err"
                            agg[(sc,kind,ec.replace("PERM ",""),cwd)] += 1
        except Exception: continue
    # corrections from history.jsonl (clean stream of YOUR prompts)
    try:
        for line in open(HIST, encoding="utf-8"):
            try: r = json.loads(line)
            except Exception: continue
            ts = (r.get("timestamp") or 0)/1000.0
            if ts < cutoff: continue
            d = (r.get("display") or "").strip()
            if not d or len(d) > 220: continue
            if d.lower().startswith(NOISE_PFX): continue
            if not CORR.search(d): continue
            sc = scope_of(r.get("project") or r.get("cwd") or "")
            agg[(sc,"corr",d.replace("\n"," ")[:120], r.get("project",""))] += 1
    except Exception: pass

    with open(EVENTS, "a", encoding="utf-8") as out:
        for (sc,kind,sig,proj), n in agg.items():
            out.write(json.dumps({"run":now,"scope":sc,"kind":kind,
                                  "sig":sig,"proj":proj,"n":n}, ensure_ascii=False)+"\n")
    open(WM,"w").write(str(now))
    _prune_events(now)
    print(f"scan: {len(agg)} signal groups captured since {time.strftime('%Y-%m-%d %H:%M', time.localtime(cutoff))}")

def _prune_events(now):
    if not os.path.exists(EVENTS): return
    keep = [l for l in open(EVENTS, encoding="utf-8")
            if (json.loads(l).get("run",0) >= now - EVENT_RETENTION_D*86400)]
    open(EVENTS,"w",encoding="utf-8").writelines(keep)

# ---------------- aggregate ----------------
def aggregate(days):
    cutoff = time.time() - days*86400
    groups = defaultdict(lambda: {"n":0,"projs":Counter()})
    if os.path.exists(EVENTS):
        for line in open(EVENTS, encoding="utf-8"):
            try: e = json.loads(line)
            except Exception: continue
            if e.get("run",0) < cutoff: continue
            g = groups[(e["scope"], e["kind"], e["sig"])]
            g["n"] += e.get("n",1)
            if e.get("proj"): g["projs"][e["proj"]] += e.get("n",1)
    rej = _ledger_fps()
    THR = {"cmd":3,"err":2,"perm":1,"corr":1}
    out = defaultdict(lambda: defaultdict(list))
    for (sc,kind,sig), g in groups.items():
        if kind=="cmd" and sig.split()[0] in PLUMBING: continue
        if g["n"] < THR.get(kind,2): continue
        fp = f"{sc}|{kind}|{sig}"
        out[sc][kind].append({"sig":sig,"n":g["n"],"fp":fp,
                              "known":fp in rej,
                              "proj":(g["projs"].most_common(1)[0][0] if g["projs"] else "")})
    for sc in out:
        for kind in out[sc]:
            out[sc][kind].sort(key=lambda x:-x["n"])
    return out

def _ledger_fps():
    s=set()
    try:
        for line in open(LEDGER, encoding="utf-8"):
            m=re.match(r"\s*fp:\s*(\S+)", line)
            if m and ("rejected" in line or "applied" in line or "snoozed" in line): s.add(m.group(1))
            elif m: s.add(m.group(1))  # any logged fp counts as seen
    except Exception: pass
    return s

LABEL={"own":"own (you) → personal tooling / CLAUDE.md",
       "work":"work=Spotware (you) → personal tooling",
       "serho":"serho (friends+bot, NOT you) → improve the platform"}
KLAB={"cmd":"repeated commands (alias/script candidates)",
      "perm":"permission prompts (→ /fewer-permission-prompts)",
      "err":"tool error classes (friction)",
      "corr":"your corrections (CLAUDE.md rule candidates)"}

def report(days):
    out = aggregate(days)
    json.dump({"generated":time.time(),"days":days,"data":out},
              open(REPORT,"w",encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"# insight-miner · report · last {days}d")
    for sc in ("own","work","serho"):
        if sc not in out: continue
        skipped = sum(1 for k in out[sc] for i in out[sc][k] if i["known"])
        hdr = f"\n===== {LABEL[sc]} ====="
        print(hdr + (f"  ({skipped} known, hidden)" if skipped else ""))
        for kind in ("cmd","perm","err","corr"):
            items=[i for i in out[sc].get(kind,[]) if not i["known"]]
            if not items: continue
            lab = KLAB[kind] if sc!="serho" or kind!="corr" else "friend/bot corrections (serho UX candidates)"
            print(f"-- {lab} --")
            for i in items[:10]:
                print(f"  {i['n']:4}×  {i['sig']}")
            print()

def tg(days):
    out = aggregate(days)
    lines=[f"🧠 Insights · {days}d"]
    for sc in ("own","work","serho"):
        if sc not in out: continue
        new=sum(len([i for i in out[sc].get(k,[]) if not i['known']]) for k in out[sc])
        top=""
        cmds=[i for i in out[sc].get("cmd",[]) if not i["known"]]
        if cmds: top=f" · top: {cmds[0]['sig']} ({cmds[0]['n']}×)"
        if new: lines.append(f"• {sc}: {new} сигналов{top}")
    lines.append("→ запусти /insight-miner review")
    print("\n".join(lines))

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv)>1 else "report"
    days = None
    if "--days" in sys.argv: days = int(sys.argv[sys.argv.index("--days")+1])
    if mode=="scan": scan(days)
    elif mode=="tg": tg(days or 7)
    else: report(days or 7)
