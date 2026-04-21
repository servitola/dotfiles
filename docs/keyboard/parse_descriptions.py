"""Parse app-specific shortcuts from Lua 5-column description column."""
import os, re
from config import LAYOUT_DIR, BUTTON_FILES

# 5-col: chord │ karabiner │ birman │ G │ description
_RE = re.compile(r'--\s+((?:[⇪⇧⌃⌥⌘]*)(?:[a-zA-Z0-9⇥⎋\[\]←→↑↓,\.;\'/\\`~\-=]|F\d+|num\d+|␣)+)'
                 r'\s+│[^│]*│[^│]*│[^│]*│\s*(.*?)\s*$')
# Continuation line (no chord)
_CONT = re.compile(r'--\s+│[^│]*│[^│]*│[^│]*│\s*(.*?)\s*$')
# App — function [/ tooltip] pattern
_APP = re.compile(r'^\s*(?:(\w[\w\s.]*?)\s*—\s*)?(.+?)(?:\s*/\s*(.+))?$')


def parse_app_descriptions():
    """Return [(chord, source_key, app, function, tooltip)] for all described shortcuts."""
    results = []
    for kn in BUTTON_FILES:
        path = os.path.join(LAYOUT_DIR, kn + ".lua")
        if not os.path.exists(path): continue
        cur_chord = None
        with open(path, encoding="utf-8") as f:
            for line in f:
                # Try chord line
                m = _RE.search(line)
                if m:
                    cur_chord = m.group(1)
                    desc = m.group(2).strip()
                else:
                    # Try continuation line
                    mc = _CONT.search(line)
                    if mc:
                        desc = mc.group(1).strip()
                    else:
                        if not line.strip().startswith("--"): cur_chord = None
                        continue
                if not desc or not cur_chord: continue
                # Skip tag-only lines (K:, B:, etc.)
                if re.match(r'^[KB\uf8ff]', desc): continue
                am = _APP.match(desc)
                if not am: continue
                app = (am.group(1) or "").strip()
                func = am.group(2).strip().lstrip("— ")
                tip = (am.group(3) or "").strip()
                if not func or func in ("???",): continue
                results.append((cur_chord, kn, app, func, tip))
    return results
