---
name: gdoc-review
description: |
  Comment-driven editing loop for large documents via Google Docs. User drops a file (docx/pdf/md/txt/html) → skill converts it to a native Google Doc and returns the link → user leaves normal Google Docs comments on chunks of text → user says "забирай" → agent reads the comments (with their quoted anchor text), edits the doc in place, replies "done" and resolves each comment. Iterative.

  Use when: "сделай гуглдок для правок", "давай через комменты в гуглдоке", "залей в гугл док", "забирай комменты", "забери правки из гуглдока", "прикрути гуглдок к этому тексту", "review this in google docs", "pull my google doc comments", "apply the comments", "turn this into a google doc for review".

  Not for: one-off docx editing without review (use the docx skill); reading a doc the skill did not create (needs a broader Drive scope — see references/setup.md).
---

# gdoc-review — редактирование документов через комменты в Google Docs

Замена старому циклу «агент кидает файл → пользователь текстом описывает правки». Теперь:
**агент кидает ссылку на гуглдок → пользователь комментит куски текста прямо в доке → говорит «забирай» → агент правит в самом доке и резолвит комменты.**

## Как это работает

Всё делается через один CLI (обёртка сама подгружает Google-креды и запускает `uv`):

```bash
gdoc="$HOME/projects/dotfiles/claude-code/skills/gdoc-review/scripts/gdoc"
```

Авторизация — **один раз** (интерактивный consent в браузере). Пользователь запускает сам:
```
! ~/projects/dotfiles/claude-code/skills/gdoc-review/scripts/gdoc auth
```
Токен сохраняется в `~/.config/gdoc-review/token.json`. Дальше всё автоматически (refresh сам).
При ошибке consent (`redirect_uri_mismatch`, `access_denied`) или `accessNotConfigured` (Drive/Docs API выключены) → `references/setup.md` — там траблшутинг OAuth и включение API.

## Рабочий цикл

### 1. Залить документ и отдать ссылку
Когда есть готовый текст/файл и пользователь хочет ревью через комменты:
```bash
"$gdoc" create /path/to/document.docx --title "Название"
# → {"id":"1AbC...","name":"...","link":"https://docs.google.com/document/d/1AbC.../edit"}
```
Поддержка: `.docx .doc .odt .rtf .html .txt .md .pdf` (pdf конвертится через OCR).
Markdown рендерится в HTML → Google сохраняет форматирование (заголовки, списки, жирный).

**Отдай пользователю ссылку** (`link`) и **запомни `id`** — он нужен на всех шагах. Скажи: «комментируй прямо в доке, потом пиши "забирай"».

**Ревью делает другой человек (не владелец токена).** Документ создаётся в Drive того аккаунта, под которым авторизован скилл, и просто расшаривается ревьюеру. Ревьюеру НЕ нужен OAuth/консоль/настройка. Два способа — выбери по типу его почты:

1. **У ревьюера есть Google-аккаунт (Gmail)** → адресный шер:
```bash
"$gdoc" create /path/doc.md --share reviewer@gmail.com          # при создании
"$gdoc" share <doc_id> --email reviewer@gmail.com --role commenter   # отдельно
```
Env `GDOC_SHARE_EMAIL` → авто-шер при `create`.

2. **У ревьюера НЕ-Google почта (Яндекс, Mail.ru и т.п.) или нет Google-аккаунта** → шер по ссылке «любой, у кого есть ссылка, может комментировать». Google-аккаунт не нужен вообще — открывает ссылку и комментит (в доке будет как аноним, текст+якорь коммента читаются нормально):
```bash
"$gdoc" create /path/doc.md --anyone commenter                  # при создании
"$gdoc" share <doc_id> --anyone commenter                       # отдельно
```
Env `GDOC_SHARE_ANYONE=commenter` → авто-режим (так настроено для друзей бота с не-Google почтой). Отдавай ревьюеру именно `link` из вывода `create` (для друга бота — через Telegram).

Роли: `writer` (правит и комментит) / `commenter` (только комменты — хватает для коммент-ревью) / `reader`. Комменты ревьюера скилл читает как обычно (файл создан приложением → scope `drive.file` их видит).

### 2. Пользователь комментит
Пользователь выделяет куски текста и оставляет обычные комменты Google Docs. Жди сигнала «забирай».

### 3. «Забирай» — вытащить комменты
```bash
"$gdoc" comments <doc_id>
# → {"count":N,"comments":[{"id","author","quote","comment","resolved","replies"}]}
```
- `quote` — **процитированный якорный текст** (где менять).
- `comment` — что пользователь просит поменять (что менять).
По умолчанию только нерешённые. `--all` — включая resolved.

### 4. Применить правки
Для точечных замен — замена по якорному тексту прямо в доке:
```bash
"$gdoc" replace <doc_id> --find "старый кусок из quote" --replace "новый текст"
# → {"occurrencesChanged":N}   (exit 2, если якорь не найден)
```
Правила:
- Бери `--find` из `quote` коммента. **`replace` матчит текст только внутри одного абзаца** — не через границы абзацев/списков. Если `quote` многострочный, содержит буллеты или обрезан Google (длинные выделения API режет) — выбери один короткий уникальный фрагмент из нужного абзаца рядом с местом правки, а не весь `quote`.
- Если фрагмент встречается несколько раз — расширь его до уникального в пределах абзаца.
- `occurrencesChanged:0` (exit 2) = не найдено → возьми другой уникальный внутренний кусок из `quote`; сверься с `"$gdoc" get <doc_id>`, чтобы увидеть реальный текст абзаца.
- `replace` вставляет **простой текст** — жирный/курсив/ссылки внутри заменяемого куска теряются. Держи `--find` минимальным (меняй только нужные слова), чтобы не сплющить форматирование вокруг.
- Для крупных структурных правок делай несколько узких `replace` подряд.
- Нужен полный текущий текст дока для контекста: `"$gdoc" get <doc_id>` (или `--json`).

### 5. Закрыть каждый коммент
После правки — ответь и зарезолвь, чтобы пользователь видел прогресс в доке:
```bash
"$gdoc" resolve <doc_id> --comment-id <id> --reply "Поправил: <кратко что сделал>"
```
Обрабатывай комменты по одному: `replace` → проверь `occurrencesChanged>0` → `resolve`. Резолвь коммент только после успешного `replace`. Спорные/непонятные комменты оставляй нерешёнными и задай по ним вопрос пользователю.

### Чек в конце цикла
Перед тем как отчитаться «готово», сверь:
- каждый обработанный коммент дал `occurrencesChanged>0` и затем был зарезолвлен (число зарезолвленных = числу применённых правок);
- перечисли пользователю комменты, чьи якоря не совпали или которые оставил спорными — с причиной.

### 6. Итерация / экспорт
Пользователь ре-ревьюит, добавляет новые комменты → снова «забирай» (шаг 3).
Когда готово — забрать финал:
```bash
"$gdoc" export <doc_id> --format docx -o /path/final.docx   # или md|txt|pdf|html|odt|rtf
```

## Важное
- Держи `doc_id` в контексте текущей работы (запиши в ответе пользователю) — все команды на него завязаны.
- Отчитывайся честно: сколько комментов обработал, какие зарезолвил, что осталось спорным.
- Резолвь коммент только после того, как `replace` вернул `occurrencesChanged>0`.
- Скилл видит только доки, созданные им самим (scope `drive.file`). Для работы с уже существующим чужим доком нужен более широкий scope, см. `references/setup.md`.

## Команды (шпаргалка)
| Команда | Что делает |
|---|---|
| `gdoc auth` | разовый OAuth-consent |
| `gdoc create <file> [--title T] [--share EMAIL]` | файл → Google Doc, вернёт `link`+`id` |
| `gdoc share <id> --email E [--role …]` / `--anyone [commenter]` | доступ ревьюеру (адресно / по ссылке) |
| `gdoc comments <id> [--all] [--raw]` | список комментов (+ якорный текст) |
| `gdoc get <id> [--json]` | текущий текст дока |
| `gdoc replace <id> --find F --replace R [--match-case]` | замена в доке |
| `gdoc resolve <id> --comment-id ID [--reply T]` | ответить + зарезолвить |
| `gdoc export <id> --format docx\|md\|txt\|pdf\|html\|odt\|rtf [-o P]` | выгрузить |
