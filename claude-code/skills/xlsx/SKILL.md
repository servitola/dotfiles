---
name: xlsx
description: |
  Generate or edit real Excel (.xlsx) spreadsheets with formatting —
  colored cells, fills, bold headers, borders, number formats, column
  widths, multiple sheets, simple formulas. Runs `openpyxl` via `uv`, so
  nothing is installed globally and it always works even after a cache
  clean. Saves into the current topic folder and sends via the bot MCP
  `send_document` tool. Also applies when the user sends an existing
  .xlsx and asks to change or restyle it.

  Use when: "сделай эксель", "сделай таблицу в экселе", "эксель с
  цветами", "excel с раскраской", "сделай xlsx", "покрась ячейки",
  "сделай .xlsx", "таблица с форматированием", "поправь эксель",
  "make an excel", "make an xlsx", "excel with colors", "colored cells",
  "formatted spreadsheet", "edit this xlsx".

  Prefer this over CSV whenever the user wants colors, formatting, bold
  headers, multiple sheets, or anything CSV can't carry. CSV is only the
  fallback when the user explicitly wants a plain, library-free table.
---

# xlsx

Generate `.xlsx` files with `openpyxl`, run via `uv` so nothing is
installed globally. Save into the current working folder, then send the
file back through the bot MCP.

**Do not fall back to CSV just because "the openpyxl env is gone."** It is
never gone. `uv run --with openpyxl` re-materializes openpyxl from PyPI on
demand — even right after `uv cache prune`, even if no python env has it
installed. If you ever hit `ModuleNotFoundError: openpyxl`, you invoked the
wrong python — use the `uv run --with openpyxl` command below, never bare
`python3`/`python` or the repo's `.venv`. CSV is only correct when the user
explicitly asks for a plain library-free table, not as a workaround.

## Workflow (create)

1. **Clarify briefly** only if the request is thin: what columns, is there
   sample data, does it need colors/conditional formatting, one sheet or
   several. One short message, max 2–3 questions. Don't interrogate.
2. **Generate the script** as `make_xlsx.py` in the current folder, from
   the template below. One script per workbook — easier to re-run after
   tweaks.
3. **Run with uv**, no venv needed:
   ```bash
   uv run --with openpyxl python make_xlsx.py
   ```
4. **Send the file** via bot MCP `send_document` with the resulting
   `.xlsx`. Short caption in Russian saying what's inside and offering
   edits.
5. **Keep the script and xlsx** in the topic folder — user may ask to
   tweak.

## Read-edit-verify loop (edit)

If the user sent a `.xlsx` or referenced one in the folder:

1. **Read** — `wb = openpyxl.load_workbook(path)`, iterate
   `ws.iter_rows(values_only=True)`, dump a flat plain-text preview of
   each sheet. Show it before editing so the user confirms the target.
2. **Edit** — mutate cells (`ws.cell(row, col).value = ...`), save as
   `edited.xlsx`. To keep existing formatting, load with the default
   (not `read_only`) and don't rebuild sheets you aren't changing.
3. **Verify** — reopen `edited.xlsx`, confirm it opens without exception
   and the expected sheets/row counts survived. If verify fails, say so —
   don't send a broken file.

## Colored-cells template (`make_xlsx.py`)

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = Workbook()
ws = wb.active
ws.title = "Данные"

headers = ["Задача", "Статус", "Приоритет"]
rows = [
    ["Собрать отчёт", "Готово",   "Высокий"],
    ["Проверить данные", "В работе", "Средний"],
    ["Отправить клиенту", "Ждёт",    "Низкий"],
]

# Header style: bold white on dark fill, centered, with border
header_fill = PatternFill("solid", fgColor="1F4E78")
header_font = Font(bold=True, color="FFFFFF")
center = Alignment(horizontal="center", vertical="center")
thin = Side(style="thin", color="BFBFBF")
border = Border(left=thin, right=thin, top=thin, bottom=thin)

for c, title in enumerate(headers, start=1):
    cell = ws.cell(row=1, column=c, value=title)
    cell.fill, cell.font, cell.alignment, cell.border = header_fill, header_font, center, border

# Status -> color mapping for conditional-style fills
status_fill = {
    "Готово":  PatternFill("solid", fgColor="C6EFCE"),  # green
    "В работе": PatternFill("solid", fgColor="FFEB9C"),  # yellow
    "Ждёт":    PatternFill("solid", fgColor="FFC7CE"),  # red
}

for r, row in enumerate(rows, start=2):
    for c, val in enumerate(row, start=1):
        cell = ws.cell(row=r, column=c, value=val)
        cell.border = border
        if c == 2:  # Статус column
            cell.fill = status_fill.get(val, PatternFill())
            cell.alignment = center

# Auto-ish column widths from content length
for c, title in enumerate(headers, start=1):
    width = max(len(str(title)), *(len(str(row[c - 1])) for row in rows)) + 4
    ws.column_dimensions[get_column_letter(c)].width = width

ws.freeze_panes = "A2"  # keep header visible when scrolling
wb.save("output.xlsx")
print("saved output.xlsx")
```

Extend as needed: `wb.create_sheet("Sheet2")` for multiple tabs;
`cell.number_format = "#,##0.00 ₽"` for money; `cell.value = "=SUM(B2:B4)"`
for formulas; `openpyxl.formatting.rule` for real conditional formatting.

## What not to do

- Don't use bare `python3` / `python` or the repo `.venv` — always
  `uv run --with openpyxl python make_xlsx.py`.
- Don't fall back to CSV to dodge a `ModuleNotFoundError` — fix the
  command instead.
- Don't invent data to fill cells; ask for the source if you don't have it.
- Don't silently send the file if the verify step failed.
