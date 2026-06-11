# Edit recipes — read / edit / verify an existing .docx

```python
# edit_doc.py — read an existing .docx, edit in place, verify
from docx import Document

SRC = "input.docx"      # what the user sent
DST = "edited.docx"

# --- READ: flat summary so the user can confirm scope ---
doc = Document(SRC)
print("--- summary ---")
for i, p in enumerate(doc.paragraphs):
    style = p.style.name if p.style else "Normal"
    text = p.text.strip()
    if text:
        print(f"[{i:3d}] ({style}) {text[:120]}")
print(f"--- {len(doc.paragraphs)} paragraphs, {len(doc.tables)} tables ---")

# --- EDIT: replace text in runs to preserve formatting ---
def replace_in_paragraph(p, old, new):
    if old not in p.text:
        return False
    # naive run-level replace; works when `old` lives within a single run
    for run in p.runs:
        if old in run.text:
            run.text = run.text.replace(old, new)
            return True
    # fallback: rewrite first run with full new text (formatting of first run kept)
    if p.runs:
        p.runs[0].text = p.text.replace(old, new)
        for r in p.runs[1:]:
            r.text = ""
        return True
    return False

# example edits — fill in actual ones from the user request
edits = [
    # ("старый текст", "новый текст"),
]
for old, new in edits:
    hit = False
    for p in doc.paragraphs:
        if replace_in_paragraph(p, old, new):
            hit = True
    if not hit:
        print(f"WARN: not found: {old!r}")

doc.save(DST)

# --- VERIFY: reopen, sanity-check ---
import sys
check = Document(DST)
orig_count = len(doc.paragraphs)
new_count  = len(check.paragraphs)
if abs(orig_count - new_count) > 2:
    print(f"FAIL: paragraph count drifted {orig_count} -> {new_count}")
    sys.exit(1)
print(f"OK: saved {DST}, paragraphs {new_count}, tables {len(check.tables)}")
```
