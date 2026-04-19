"""Parse active Hammerspoon chord entries from Lua code lines."""
import os
import re
from config import LAYOUT_DIR, BUTTON_FILES

_ENTRY_RE = re.compile(
    r'\{\s*chord\s*=\s*"([^"]+)"'
    r'.*?(?:app\s*=\s*"([^"]+)"|fn\s*=\s*"([^"]+)")'
)


def parse_active_entries():
    """Return list of dicts: {chord, app|fn, source_key} from all Lua files."""
    entries = []
    for key_name in BUTTON_FILES:
        path = os.path.join(LAYOUT_DIR, key_name + ".lua")
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith("--"):
                    continue
                m = _ENTRY_RE.search(stripped)
                if not m:
                    continue
                entry = {"chord": m.group(1), "source_key": key_name}
                if m.group(2):
                    entry["app"] = m.group(2)
                elif m.group(3):
                    entry["fn"] = m.group(3)
                entries.append(entry)
    return entries
