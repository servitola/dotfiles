---
name: powerpoint
description: |
  Generate or edit PowerPoint (.pptx) presentations from a description.
  Builds slide structure, fills in titles/bullets, adds simple charts and
  images, saves the file into the current topic folder, and sends it to
  the user via the bot MCP `send_document` tool.

  Use when user asks any of: "сделай презентацию", "сделай слайды",
  "сделай пптх", "сделай pptx", "сделай powerpoint", "сделай доклад",
  "оформи слайдами", "собери презентацию", "переделай презентацию",
  "поправь слайды", "make a presentation", "make slides", "build a deck",
  "generate pptx", "edit this pptx".

  Also: when user sends an existing `.pptx` file and asks to change,
  rework, translate, restyle, or extend it.
---

# powerpoint

Generate `.pptx` files with `python-pptx`, run via `uv` so nothing is
installed globally. Save into the current working folder, then send the
file back through the bot MCP.

## Workflow

1. **Clarify briefly** if the request is too thin. Ask for: тема,
   аудитория, сколько слайдов примерно, есть ли существующий шаблон/файл.
   One short message, max 2-3 questions. Don't interrogate.
2. **Outline first.** Draft a slide-by-slide plan as plain text and show
   it. Wait for ok or edits before generating the file. This is the cheap
   step — fix structure here, not in pptx.
3. **Generate the script** as `make_deck.py` in the current folder. Use
   the template below. Keep one script per deck — easier to re-run after
   tweaks.
4. **Run with uv**, no venv needed:
   ```bash
   uv run --with python-pptx --with pillow --with matplotlib python make_deck.py
   ```
5. **Send the file** via bot MCP:
   - `send_document` with the resulting `.pptx`.
   - Short caption in Russian saying what's inside and offering edits.
6. **Keep the script and pptx** in the topic folder. Don't delete — user
   may ask to tweak.

## Editing an existing .pptx

If user sent a file or referenced one in the topic folder:
- Read it with `python-pptx`: iterate `prs.slides`, dump titles + bullets
  to text first, show that as a summary.
- Apply edits in-place on a copy (`prs.save("edited.pptx")`), don't
  rebuild from scratch unless user asked for a redesign.
- For text replacement walk `shape.text_frame.paragraphs[i].runs[j].text`
  — replacing `text_frame.text` wipes formatting.

## Style defaults

If no template/brand given, use this minimal clean style:
- Title font: Helvetica Neue / Calibri, 36pt, bold, dark gray `#222`.
- Body font: same family, 20pt, `#333`.
- Accent color: `#2E6FDB` (calm blue) for bars, dividers.
- White background. No clipart. No shadows. No emojis unless asked.
- 16:9 aspect ratio.

For friend / mama / friend bots: keep it tasteful, no corporate cringe.
For friend specifically (medical content): sober, no emoji icons unless
explicitly requested.

## Template — generator script

```python
# make_deck.py — generate a .pptx in the current folder
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE

ACCENT = RGBColor(0x2E, 0x6F, 0xDB)
TITLE  = RGBColor(0x22, 0x22, 0x22)
BODY   = RGBColor(0x33, 0x33, 0x33)

prs = Presentation()
prs.slide_width  = Inches(13.333)   # 16:9
prs.slide_height = Inches(7.5)

def blank():
    return prs.slides.add_slide(prs.slide_layouts[6])  # blank layout

def add_text(slide, x, y, w, h, text, *, size=20, bold=False, color=BODY,
             align=None):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    if align is not None:
        p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.name = "Helvetica Neue"
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color
    return tf

def title_slide(title, subtitle=""):
    s = blank()
    add_text(s, 1, 2.6, 11.3, 1.2, title,    size=44, bold=True, color=TITLE)
    if subtitle:
        add_text(s, 1, 4.0, 11.3, 0.8, subtitle, size=22, color=BODY)
    # accent bar
    bar = s.shapes.add_shape(MSO_SHAPE.RECTANGLE,
                             Inches(1), Inches(3.7), Inches(0.6), Inches(0.08))
    bar.fill.solid(); bar.fill.fore_color.rgb = ACCENT
    bar.line.fill.background()
    return s

def bullets_slide(title, bullets):
    s = blank()
    add_text(s, 0.6, 0.5, 12.1, 0.8, title, size=30, bold=True, color=TITLE)
    box = s.shapes.add_textbox(Inches(0.6), Inches(1.6),
                               Inches(12.1), Inches(5.4))
    tf = box.text_frame; tf.word_wrap = True
    for i, b in enumerate(bullets):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.level = 0
        run = p.add_run(); run.text = "• " + b
        run.font.name = "Helvetica Neue"
        run.font.size = Pt(20); run.font.color.rgb = BODY
        p.space_after = Pt(10)
    return s

def section_slide(title):
    s = blank()
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = RGBColor(0xF5, 0xF6, 0xF8)
    add_text(s, 1, 3.2, 11.3, 1.2, title, size=40, bold=True, color=ACCENT)
    return s

# --- deck content goes here ---
title_slide("Заголовок презентации", "Подзаголовок / автор / дата")
section_slide("Раздел 1")
bullets_slide("Главные мысли", [
    "Первый тезис в одну строку",
    "Второй тезис",
    "Третий тезис",
])

prs.save("deck.pptx")
print("saved deck.pptx")
```

## Charts (when actually needed)

Don't bolt a chart onto every deck. Only when user asks for one or the
content is obviously numeric.

```python
# inside the script — render a chart with matplotlib, embed as image
import matplotlib.pyplot as plt
fig, ax = plt.subplots(figsize=(8, 4.5), dpi=150)
ax.bar(["A", "B", "C"], [3, 7, 5], color="#2E6FDB")
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig("chart1.png")
plt.close(fig)

s = blank()
add_text(s, 0.6, 0.5, 12.1, 0.8, "Заголовок графика",
         size=30, bold=True, color=TITLE)
s.shapes.add_picture("chart1.png", Inches(1.5), Inches(1.7),
                     width=Inches(10))
```

## Images

If user provided an image in the topic folder, embed via
`add_picture(path, Inches(x), Inches(y), width=Inches(w))`. Don't fetch
external images unless asked.

## What not to do

- Don't open PowerPoint or rely on macOS automation — `python-pptx` only.
- Don't generate huge decks (>30 slides) without confirming.
- Don't invent numbers/quotes/sources to fill slides. Ask if you don't
  have the content.
- Don't use emoji-as-bullets (✅ 🚀 💡) unless user asked.
- Don't pollute the topic folder with intermediate files — clean up
  `chart*.png` after embedding if user doesn't need them as separate
  files.
