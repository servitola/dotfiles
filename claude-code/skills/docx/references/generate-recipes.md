# Generate recipes — new .docx from scratch

Contents:
- [Template — generator script](#template--generator-script) — `make_doc.py`: A4 page setup, base style, heading/para/bullets/numbered/table helpers, title page
- [Images](#images) — embedding and centering pictures
- [Tables](#tables) — when to use the `table()` helper vs a separate `.xlsx`

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
