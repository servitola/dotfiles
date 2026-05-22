"""Parse key bindings from Lua 5-column comments: chord │ karabiner │ birman │ G │ desc."""
import os, re
from config import LAYOUT_DIR, BUTTON_FILES
from labels import COMMENT_OUTPUT_LABELS
from _chord_regex import CHORD_ROW as _RE, CHORD_ROW_FULL as _RE_FULL
_TAG_RE = re.compile(r'^(K|B|\uf8ff)(→([\w\s]+))?:\s*(.*)$')
_FINT = re.compile(r'^F1[3-9]$|^F20$')
_CMAP = re.compile(r'^[^\s]{1,3}(\s+[^\s]{1,3}){1,}$')
_cl = lambda s: s.replace("\uf8ff","").lstrip("\u2014—-📝🌐🔗 ").strip()


def _label_from_output(out):
    if _FINT.match(out): return None
    if _CMAP.match(out): out = out.split()[0]
    return COMMENT_OUTPUT_LABELS.get(out, out)


def parse_comment_entries():
    entries = []
    for kn in BUTTON_FILES:
        path = os.path.join(LAYOUT_DIR, kn + ".lua")
        if not os.path.exists(path): continue
        with open(path, encoding="utf-8") as f:
            for line in f:
                m = _RE.search(line)
                if not m: continue
                chord, karabiner, birman, desc = (
                    m.group(1), m.group(2).strip(), m.group(3).strip(), m.group(4).strip())
                if karabiner:
                    label = _label_from_output(karabiner)
                    if label:
                        entries.append({"chord": chord, "label": label,
                                        "source_key": kn, "source_tag": "K"})
                elif desc:
                    tm = _TAG_RE.match(desc)
                    if not tm: continue
                    tag, app_hint, raw = tm.group(1), tm.group(3), tm.group(4)
                    label = _cl(raw) if raw else (_label_from_output(birman) if birman else None)
                    if not label: continue
                    e = {"chord": chord, "label": label, "source_key": kn, "source_tag": tag}
                    if app_hint: e["app_hint"] = app_hint.strip()
                    entries.append(e)
    return entries


# ── Full 5-column parser for detail table ──────────────────────────
_CONT2 = re.compile(r'--\s+│[^│]*│[^│]*│[^│]*│\s*(.*?)\s*$')
_DESC_APP = re.compile(r'^\s*(?:(\w[\w\s.]*?)\s*—\s*)?(.+?)(?:\s*/\s*(.+))?$')
_STRIP = re.compile(r'^[🌐📝🔗📁🔄ℝ⚠️]\s*')


def _pdesc(raw):
    if not raw or raw in ('???', '↓'): return None
    if re.match(r'^[KB]\uf8ff?:', raw) or re.match(r'^\uf8ff', raw): return None
    d = _STRIP.sub('', raw).strip()
    d = re.sub(r'\s*—\s*CUSTOM\s*$', '', d)
    if not d: return None
    m = _DESC_APP.match(d)
    if not m: return None
    app = (m.group(1) or "").strip()
    func = m.group(2).strip().lstrip("— ")
    return (app, func) if func else None


def parse_full_entries():
    """Return ALL chord rows: {chord, source_key, karabiner, birman, global, descriptions}."""
    entries = []
    for kn in BUTTON_FILES:
        path = os.path.join(LAYOUT_DIR, kn + ".lua")
        if not os.path.exists(path): continue
        cur = None
        with open(path, encoding="utf-8") as f:
            for line in f:
                m = _RE_FULL.search(line)
                if m:
                    if cur: entries.append(cur)
                    desc = m.group(5).strip()
                    cur = {"chord": m.group(1), "source_key": kn,
                           "karabiner": m.group(2).strip(), "birman": m.group(3).strip(),
                           "is_global": '✓' in m.group(4), "descriptions": []}
                    d = _pdesc(desc)
                    if d: cur["descriptions"].append(d)
                else:
                    mc = _CONT2.search(line)
                    if mc and cur:
                        d = _pdesc(mc.group(1).strip())
                        if d: cur["descriptions"].append(d)
                    elif not line.strip().startswith("--"):
                        if cur: entries.append(cur)
                        cur = None
        if cur: entries.append(cur)
    return entries
