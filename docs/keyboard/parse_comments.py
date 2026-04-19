"""Parse system-wide key bindings documented in Lua file comments."""
import os, re
from config import LAYOUT_DIR, BUTTON_FILES
from labels import COMMENT_OUTPUT_LABELS, COMMENT_DESC_LABELS

_RE = re.compile(r'--\s+((?:[⇪⇧⌃⌥⌘]*)(?:[a-zA-Z0-9⇥⎋\[\]←→↑↓,\.;\'/\\`~\-=]|F\d+|num\d+|␣)+)'
                 r'\s+│([^│]*)│\s*(.*?)\s*$')
_APP = ("Rider","VSCode","Fork","Music","Mail","Finder","Browser","Telegram","IINA","Warp",
    "Google","Raycast","iTerm","XCode","Claude","YouTube","Unix","Birman","BrowserVim",
    "AltTab","karabiner","itsycal","WorkBot","Activity","Shotr","AyuGram","Simulator",
    "Yandex","OrbStack","Zoom","Heroes","Obsidian")
_FINT = re.compile(r'^F1[3-9]$|^F20$')
_CMAP = re.compile(r'^[^\s]{1,3}(\s+[^\s]{1,3}){1,}$')


def _useful(out, desc):
    if not out and not desc: return False
    if out and _FINT.match(out): return False
    if out: return True
    if desc and not desc.startswith(("—","\u2014")):
        if any(desc.startswith(p) for p in _APP): return False
    return bool(desc)


def parse_comment_entries():
    entries = []
    for kn in BUTTON_FILES:
        path = os.path.join(LAYOUT_DIR, kn + ".lua")
        if not os.path.exists(path): continue
        with open(path, encoding="utf-8") as f:
            for line in f:
                m = _RE.search(line)
                if not m: continue
                chord, out, desc = m.group(1), m.group(2).strip(), m.group(3).strip()
                if not _useful(out, desc): continue
                if out:
                    # For character maps like "` ё §", use first char
                    if _CMAP.match(out):
                        out = out.split()[0]
                    label = COMMENT_OUTPUT_LABELS.get(out, out)
                else:
                    label = COMMENT_DESC_LABELS.get(desc.lstrip("—\u2014 "), desc.lstrip("—\u2014 "))
                label = label.replace("\uf8ff","").strip()  # remove Apple logo char
                label = label.lstrip("\u2014—-📝🌐🔗 ").strip()  # dashes + emoji
                if len(label) > 14: label = label[:13] + "\u2026"
                entries.append({"chord": chord, "label": label, "source_key": kn})
    return entries
