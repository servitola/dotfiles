---
name: docx
description: |
  Generate or edit Word (.docx) documents from a description. Builds
  headings, paragraphs, bullet/numbered lists, simple tables and embedded
  images, saves the file into the current topic folder, and sends it to
  the user via the bot MCP `send_document` tool.

  Use when user asks any of: "сделай реферат", "напиши доклад",
  "сделай документ", "сделай ворд", "сделай docx", "оформи в ворде",
  "собери реферат", "переделай документ", "поправь docx",
  "напиши эссе", "сделай курсовую", "make a docx", "write a report",
  "write an essay", "edit this docx".

  Also: when user sends an existing `.docx` file and asks to change,
  rework, translate, restyle, or extend it.
---

# docx

Generate `.docx` files with `python-docx`, run via `uv` so nothing is
installed globally. Save into the current working folder, then send the
file back through the bot MCP.

Most users here are writing рефераты, доклады, эссе, материалы — not
legal docs with tracked changes. `python-docx` is enough. If a user
sends a complex doc with track changes / comments / unusual formatting
and asks to edit it surgically, warn them that some formatting may be
lost and offer to rewrite the section as plain text instead.

## Workflow

1. **Clarify briefly** if the request is too thin. Ask for: тема,
   объём (страниц / слов), формат (реферат / доклад / эссе / отчёт),
   нужны ли источники, есть ли требования по оформлению (ГОСТ, MLA,
   произвольно). One short message, max 2–3 questions. Don't interrogate.
2. **Outline first.** Draft the structure as plain text (заголовки +
   1–2 строки на каждый раздел) and show it. Wait for ok or edits
   before generating the file. This is the cheap step — fix structure
   here, not in docx.
3. **Generate the script** as `make_doc.py` in the current folder. Use
   the template below. Keep one script per document — easier to re-run
   after tweaks.
4. **Run with uv**, no venv needed:
   ```bash
   uv run --with python-docx --with pillow python make_doc.py
   ```
5. **Send the file** via bot MCP:
   - `send_document` with the resulting `.docx`.
   - Short caption in Russian saying what's inside and offering edits.
6. **Keep the script and docx** in the topic folder. Don't delete — user
   may ask to tweak.

## Read-edit-verify loop (when editing an existing .docx)

If user sent a file or referenced one in the topic folder, work in
three steps — same idea as coding agents on source files:

1. **Read** — load with `python-docx`, iterate `doc.paragraphs` and
   `doc.tables`, dump to a flat plain-text view (heading level + text).
   Show this summary to the user before editing — so they confirm we're
   editing the right thing.
2. **Edit** — apply changes on a copy of the doc object, save as
   `edited.docx`. For text replacement walk
   `paragraph.runs[j].text` — replacing `paragraph.text` wipes
   formatting. For new paragraphs use `doc.add_paragraph(..., style=...)`.
3. **Verify** — reopen the saved `edited.docx` with `python-docx` and
   check: file opens without exception, paragraph count is within
   expected range (didn't accidentally drop sections), all headings from
   the original outline are still present (unless user asked to remove
   them). If anything fails — say so, don't silently send a broken file.

## Style defaults

If no template/brand given, use a clean academic-leaning style:
- Body font: Times New Roman или Calibri, 12pt, межстрочный 1.5.
- Headings: same family, bold, 16pt (H1) / 14pt (H2) / 12pt (H3).
- Margins: 2.5 cm со всех сторон (близко к ГОСТ / MS default).
- Чёрный текст на белом, без цветных акцентов в основном тексте.
- Без emoji в заголовках/буллетах unless asked.
- Numbered headings for рефератов/докладов (`1.`, `1.1.`, …) если объём > 3 страниц; иначе без нумерации.

For friend/family bots: keep it sober. For friend
specifically (medical content): formal academic tone, references in
Vancouver style if the user asks for sources.

## Template — generator script

```python
# make_doc.py — generate a .docx in the current folder
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

doc = Document()

# --- page setup: A4, 2.5cm margins ---
section = doc.sections[0]
section.page_height = Cm(29.7)
section.page_width  = Cm(21.0)
section.top_margin    = Cm(2.5)
section.bottom_margin = Cm(2.5)
section.left_margin   = Cm(2.5)
section.right_margin  = Cm(2.5)

# --- base style: Times New Roman 12pt, 1.5 line spacing ---
style = doc.styles["Normal"]
style.font.name = "Times New Roman"
style.font.size = Pt(12)
style.element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
pf = style.paragraph_format
pf.line_spacing = 1.5
pf.space_after  = Pt(0)

def heading(text, level=1, *, align=None):
    h = doc.add_heading(text, level=level)
    if align is not None:
        h.alignment = align
    for run in h.runs:
        run.font.name = "Times New Roman"
        run.font.color.rgb = RGBColor(0, 0, 0)
        run.font.size = Pt({1: 16, 2: 14, 3: 12}.get(level, 12))
    return h

def para(text, *, bold=False, italic=False, align=None, indent_first=True):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    if indent_first:
        p.paragraph_format.first_line_indent = Cm(1.25)
    run = p.add_run(text)
    run.font.name = "Times New Roman"
    run.font.size = Pt(12)
    run.bold = bold
    run.italic = italic
    return p

def bullets(items):
    for it in items:
        p = doc.add_paragraph(it, style="List Bullet")
        for run in p.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(12)

def numbered(items):
    for it in items:
        p = doc.add_paragraph(it, style="List Number")
        for run in p.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(12)

def table(rows, *, header=True):
    t = doc.add_table(rows=len(rows), cols=len(rows[0]))
    t.style = "Table Grid"
    for i, row in enumerate(rows):
        for j, cell_text in enumerate(row):
            cell = t.rows[i].cells[j]
            cell.text = ""
            p = cell.paragraphs[0]
            run = p.add_run(str(cell_text))
            run.font.name = "Times New Roman"
            run.font.size = Pt(12)
            run.bold = (header and i == 0)
    return t

def page_break():
    doc.add_page_break()

# --- title page ---
heading("Тема работы", level=1, align=WD_ALIGN_PARAGRAPH.CENTER)
para("Автор · Группа · Год", align=WD_ALIGN_PARAGRAPH.CENTER, indent_first=False)
page_break()

# --- body goes here ---
heading("Введение", level=1)
para("Вступительный абзац в одну-две фразы, обозначающий тему и цель работы.")

heading("Основная часть", level=1)
para("Содержательный текст с аргументами и примерами.")
bullets([
    "Первый тезис",
    "Второй тезис",
    "Третий тезис",
])

heading("Заключение", level=1)
para("Краткие выводы по работе.")

doc.save("doc.docx")
print("saved doc.docx")
```

## Editing template — read / edit / verify

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

## Images

If user provided an image in the topic folder, embed via
`doc.add_picture(path, width=Cm(W))`. Don't fetch external images unless
asked. Centre with:

```python
p = doc.paragraphs[-1]
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
```

## Tables

Use the `table()` helper from the template. Don't try to recreate complex
Excel-style tables in Word — if the user wants that, suggest a separate
`.xlsx`.

## What not to do

- Don't open Word or rely on macOS automation — `python-docx` only.
- Don't generate huge docs (>30 pages) without confirming.
- Don't invent numbers/quotes/sources to fill the document. If the user
  needs citations, ask for sources first.
- Don't use emoji-as-bullets (✅ 🚀 💡) unless user asked.
- Don't silently send the file if `verify` step failed — tell the user
  what went wrong.
- Don't pollute the topic folder with intermediate files — clean up
  `input.docx`/`edited.docx` duplicates if the user only needs the final.
