---
name: powerpoint
description: |
  Create, read, edit, and QA .pptx presentations — slides, speaker notes, templates, layouts — with strong visual design guidance.

  Use when: "сделай презентацию", "создай слайды", "отредактируй pptx", "вытащи текст из презентации", "create a deck", "make slides", "edit this pptx", "build a pitch deck"
---

# Powerpoint Skill

## When to use

Use this skill any time a .pptx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or presentations; reading, parsing, or extracting text from any .pptx file (even if the extracted content will be used elsewhere, like in an email or summary); editing, modifying, or updating existing presentations; combining or splitting slide files; working with templates, layouts, speaker notes, or comments. Trigger whenever the user mentions "deck," "slides," "presentation," or references a .pptx filename, regardless of what they plan to do with the content afterward. If a .pptx file needs to be opened, created, or touched, use this skill.

## What do you need?

```
Read / extract content only?
└─ use the commands in Reading Content below — no references needed

Create or edit a deck?
├─ Template or existing .pptx available → read references/editing.md
└─ From scratch (no template)         → read references/pptxgenjs.md
```

Load the smallest set of references that fits the task.

## Reading Content

```bash
# Text extraction
python -m markitdown presentation.pptx

# Visual overview
python scripts/thumbnail.py presentation.pptx

# Raw XML
python scripts/office/unpack.py presentation.pptx unpacked/
```

## Editing Workflow

1. Analyze template with `thumbnail.py`
2. Unpack → manipulate slides → edit content → clean → pack

Follow the full workflow in [editing.md](references/editing.md) — template analysis, slide operations, XML editing rules, scripts reference, common pitfalls.

## Creating from Scratch

Use when no template or reference presentation is available. Build with PptxGenJS following [pptxgenjs.md](references/pptxgenjs.md) — setup, text, images, icons, tables, charts, masters, pitfalls.

## Design

Before building any slides, pick a palette, font pairing, and per-slide layouts from [design.md](references/design.md) — color palettes, typography pairings, layout options, common visual mistakes. Plain bullets on a white background won't impress anyone.

## QA (Required)

After every create or edit, run the full verification loop from [qa.md](references/qa.md) — content QA via markitdown, visual QA with a fresh-eyes agent, converting slides to images, fix-and-verify cycles. Do not declare success until at least one fix-and-verify cycle is complete.

## Dependencies

- `pip install "markitdown[pptx]"` - text extraction
- `pip install Pillow` - thumbnail grids
- `npm install -g pptxgenjs` - creating from scratch
- LibreOffice (`soffice`) - PDF conversion (auto-configured for sandboxed environments via `scripts/office/soffice.py`)
- Poppler (`pdftoppm`) - PDF to images
