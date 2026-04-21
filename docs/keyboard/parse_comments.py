"""Parse key bindings from Lua 5-column comments: chord │ karabiner │ birman │ G │ desc."""
import os, re
from config import LAYOUT_DIR, BUTTON_FILES
from labels import COMMENT_OUTPUT_LABELS

# 5-col: chord │ karabiner │ birman │ global │ description
_RE = re.compile(r'--\s+((?:[⇪⇧⌃⌥⌘]*)(?:[a-zA-Z0-9⇥⎋\[\]←→↑↓,\.;\'/\\`~\-=]|F\d+|num\d+|␣)+)'
                 r'\s+│([^│]*)│([^│]*)│[^│]*│\s*(.*?)\s*$')
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
