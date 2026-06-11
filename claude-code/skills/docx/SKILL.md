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

## Which mode?

New document from a description (реферат, доклад, эссе, отчёт)?
└─ Create → follow [Workflow](#workflow-create), script template in
   [generate-recipes.md](references/generate-recipes.md)

User sent an existing `.docx` or referenced one in the topic folder?
└─ Edit → follow [Read-edit-verify loop](#read-edit-verify-loop-edit),
   script template in [edit-recipes.md](references/edit-recipes.md)

Load only the reference for the chosen mode — the other branch's recipes
are dead weight in context.

## Workflow (create)

1. **Clarify briefly** if the request is too thin. Ask for: тема,
   объём (страниц / слов), формат (реферат / доклад / эссе / отчёт),
   нужны ли источники, есть ли требования по оформлению (ГОСТ, MLA,
   произвольно). One short message, max 2–3 questions. Don't interrogate.
2. **Outline first.** Draft the structure as plain text (заголовки +
   1–2 строки на каждый раздел) and show it. Wait for ok or edits
   before generating the file. This is the cheap step — fix structure
   here, not in docx.
3. **Generate the script** as `make_doc.py` in the current folder,
   starting from the template in
   [generate-recipes.md](references/generate-recipes.md) (A4 page setup,
   heading/para/bullets/numbered/table helpers, title page; also image
   embedding and table recipes). Keep one script per document — easier
   to re-run after tweaks.
4. **Run with uv**, no venv needed:
   ```bash
   uv run --with python-docx --with pillow python make_doc.py
   ```
5. **Send the file** via bot MCP:
   - `send_document` with the resulting `.docx`.
   - Short caption in Russian saying what's inside and offering edits.
6. **Keep the script and docx** in the topic folder. Don't delete — user
   may ask to tweak.

## Read-edit-verify loop (edit)

If user sent a file or referenced one in the topic folder, work in
three steps — same idea as coding agents on source files. Build the
script from the template in [edit-recipes.md](references/edit-recipes.md)
(flat summary dump, run-level text replace, post-save sanity checks),
then run it with the same `uv run` command as above.

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

For friend/family bot topics: keep it sober. When the topic's content
domain is academic or medical: formal academic tone, references in
Vancouver style if the user asks for sources.

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
