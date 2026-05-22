---
name: create-regular-website
description: |
  Creates and maintains a personal website for a non-technical user — blog,
  portfolio, gallery, personal landing page, or any combination. Content
  lives as files in the user's topic folder; the site publishes to
  Surge.sh (accessible from Russia without VPN).

  Trigger on initialization when the user says things like: "I want a
  website", "make me a site", "let's start a blog", "I want a portfolio",
  "personal page", "site about [topic]", in any language.

  Trigger on content work — only when the current folder contains
  `site.yaml` — when the user says: "new post", "here is text", "for the
  blog", "for the gallery", "this is my work", "here are photos", "about
  me", "rename the site", "different color", "delete the post", "publish",
  "update the site", "show the link", "how does it look now".

  SKIP when:
  - The folder has no `site.yaml` AND the user is not asking to create a
    site (e.g. "new note for ideas", "save this somewhere").
  - The user asks about how the site works technically (npm, deploy, git)
    — that is for the operator, not the user.
  - The user asks for a site for someone else (different topic, possibly
    different stack).
---

# create-regular-website

## User context

The user is non-technical. They talk to you in Telegram (or chat); each
of their topics maps to a folder here. They send messages and files —
your job is to recognize intent and place content in the right place.

Never mention jargon: yaml, markdown, deploy, slug, frontmatter, build,
git. For them this is "my website". Respond in their language, warmly,
without technical talk.

A topic that contains `site.yaml` is a site topic. Folders `posts/`,
`projects/`, `gallery/`, `images/` hold user content. Folder `engine/`
holds build code — you never edit it directly.

## When this skill activates

| Signal | Action |
|---|---|
| User asks for a site in an empty/almost-empty topic | Initialize (below) |
| Folder has `site.yaml` and user sends content | Route content (below) |
| "publish" / "update site" in a site topic | Deploy |
| "delete X" / "remove Y" | Plan-and-confirm, then act |
| "show me Z" / "how many posts" / "what does it look like" | Status report |

## Initialization

Run once per topic. Flow:

1. Ask **two** quick questions (no more — keep it light):
   - What should the site be called (this goes in the header)?
   - What is the main thing first — blog, portfolio, photos, or just a
     personal page? This guides where to start; sections can be added
     later anytime.
2. Run the initializer:
   ```
   bash ~/projects/dotfiles/claude-code/shared/skills/create-regular-website/scripts/init-topic.sh "$PWD"
   ```
3. Edit `site.yaml`: set `name` to what the user chose. If the user
   speaks Russian by default, set `lang: ru`; for English `lang: en`.
   Other languages — see `references/style-language.md`.
4. Confirm to the user in their language, *without listing files or
   folders*. Something like: "Done, you now have a site called X. Send
   me photos, texts, ideas — I will sort them. Say 'publish' when you
   want it live."

## Routing content

When the user sends text or a file, identify the type and place it.
If the intent is ambiguous, ask in **one short sentence** — do not
guess silently.

### Blog post

Triggers: "new post", "for the blog", "I want to write about…", or just
a long coherent text with no other context.

Action: create `posts/<slug>.md`. The slug is short, in the user's
language, hyphenated, derived from the topic. Frontmatter:

```yaml
---
title: "..."
date: 2026-05-15
description: "one-line preview"   # if it can be inferred
cover: images/...jpg              # if the user attached an image
---

post body
```

`date` — today's date in the user's timezone (read it from the global
user profile; UTC+7 for Novosibirsk, etc.). If the user says
"yesterday", "last week", compute and write a concrete date.

### Image attached to a post

If context is "for this post" / "to that article" — save as
`images/<post-slug>-<n>.jpg` and embed a markdown image link in the
post body. If context is unclear — ask.

### Photo album

Triggers: "for the gallery", "here are photos", "album", "pictures from…".

If albums already exist and the user did not specify which — ask in
one sentence: "Which album — there is 'summer', 'trip'? Or a new
name?"

Action: place photos in `gallery/<album-name>/` with descriptive
filenames (or `01.jpg`, `02.jpg` etc.). Captions, if provided, in
`gallery/<album-name>/captions.yaml`:

```yaml
01.jpg: "caption for the first"
02.jpg: "caption for the second"
```

### Portfolio project

Triggers: "here is my work", "this is for portfolio", "project X".

Create `projects/<slug>/` with:
```
projects/<slug>/
  description.md         (frontmatter: name, year, link)
  cover.jpg              (main image)
  images/                (additional shots, optional)
```

### About page

Triggers: "about me", "let me tell you about myself", "my bio".

Action: edit `about.md`. **Do not overwrite** existing text without
confirmation. Show a plan: "Right now it says 'X'. I will add 'Y',
rephrase 'Z'. Okay?" Then change.

### Contacts and socials

Triggers: "my Instagram", "Telegram", "email", "how to reach me".

Edit `links.yaml`. Confirm briefly afterwards: "Added Instagram and
Telegram, they will appear at the bottom of the site."

### Design changes

Triggers: "different color", "darker", "brighter", "more minimal", "make
it like this" (with screenshot), "rename the site".

Edit `site.yaml` (the `theme` section). For translating natural
language to specific values, follow guidance in
[references/style-language.md](references/style-language.md) — it has
ready palettes (warm, minimal, green, dark, etc.) and font pairings.

## Edits and deletions (Plan-Validate-Execute)

When the user asks to **delete / rewrite / replace** something, do not
do it immediately. Show the plan in one sentence and wait for "yes".

| User says | Show |
|---|---|
| "delete the post about X" | "I'll delete the post 'X' from March 12, okay?" |
| "remove this photo" | "I'll remove photo N from album 'summer', okay?" |
| "rewrite the about page" | "Currently it says: '…'. Rewrite to: '…'?" |
| "take the blog off the site" | "I'll hide the 'Blog' section (files stay, can bring it back). Okay?" |

After "yes" — act. After "no" — keep as-is.

Reason: the topic auto-commits on every change, so "accidentally
deleted" enters git history, but recovery for a non-technical user is
hard. Better to ask once.

**Hide vs delete**: "remove the section" → set `site.yaml →
sections.<name>: false`, files stay. "Delete it for good" → remove
the files.

## Status reporting

Triggers: "how many posts", "give me the link", "what is it called
now", "what's in my gallery".

Reply with a natural sentence, not file lists. Sources:
- Site name, colors → `site.yaml`
- Post count → entries in `posts/*.md`
- Albums → subfolders of `gallery/`
- Projects → subfolders of `projects/`
- URL → `https://<transliterated-topic-name>.surge.sh` (computed in
  `deploy.sh`)

## Publish

Triggers: "publish", "update site", "can I see it", "show".

One shell call:
```
bash ~/projects/dotfiles/claude-code/shared/skills/create-regular-website/scripts/deploy.sh "$PWD"
```

The script builds the site and pushes it to Surge.sh, prints the URL.

After a successful deploy:
1. Send the URL via `mcp__bot__send_message` if Telegram MCP is wired.
2. Reply in the user's language: "Done, site updated: <URL>. Should be
   live in a few seconds."

If a Playwright MCP is available, take a screenshot of the home page
and send via `mcp__bot__send_image` with a short caption.

**Preview**: if the user says "let me check first" or you want to show
a big change before going live:
```
bash .../scripts/deploy.sh "$PWD" --preview
```
Deploys to `<slug>-preview.surge.sh` — separate URL, production untouched.

## When something breaks

Read the error, do not show stack traces to the user. Common cases:

- `SURGE_LOGIN / SURGE_TOKEN must be set` — credentials missing; escalate
  to the operator.
- `npm ERR! ...` — engine deps broken; run `update-engine.sh`.
- `domain is already in use` / `not authorized to deploy to <slug>.surge.sh`
  — someone else already owns that subdomain on Surge. Ask the user to
  rename the site topic to something more unique, then redeploy.
- Cyrillic in topic name → transliterated to slug, expected.

If you cannot fix it in 1–2 attempts, say in the user's language:
"Something is off with my tools — please ping the operator, they will
fix it quickly."

## Engine updates

Triggers from user: "update the engine", "something is broken, fix it",
"the design is glitching":
```
bash .../scripts/update-engine.sh "$PWD"
```

Refreshes the engine code without touching user content.

## Multiple sites

If the user has several site topics, each is independent. Surge domain
= `<transliterated-topic-name>.surge.sh`. Each gets its own URL.
Deploying one does not affect others.

## Voice messages

If audio arrives, it may come transcribed (Telegram bot can transcribe)
or as a file. If as a file, transcribe via available tools, then treat
the transcript as regular text from the user.

## Conversation principles

- **Describe actions in plain words**, not technical names. Not "I'm
  creating posts/plants.md", but "I'm saving your post about plants".
  Technical words distract them.
- **Confirm briefly after each action**: "Saved. The album now has 3
  photos." They need to see things working.
- **Before losing data — always plan + confirm**. See deletions section.
- **Ask one short question when ambiguous**, never silently guess. A
  one-line "is this for the blog or just to save?" is better than
  putting it in the wrong place.

## Topic layout (what gets scaffolded)

The template the AI copies into a new site topic lives at
`~/projects/dotfiles/claude-code/shared/skills/create-regular-website/topic-template/`.
After init the user's topic looks like:

```
site.yaml          - settings (name, colors, sections)
links.yaml         - socials
home.md            - hero text on the front page
about.md           - about page
posts/             - blog posts
images/            - shared images
projects/          - portfolio entries
gallery/           - photo albums
engine/            - Astro build code (do not touch)
built-site/        - last built output (gitignored)
README.md          - tiny how-to for the user
```

## Example dialogues

These are patterns — copy the tone, not the exact lines. Adapt to
the user's language.

### Example 1 — initialization (Russian-speaking user)

> **User**: хочу сайт, типа маленький, про мои растения
> **You**: круто! Два вопроса: как назвать сайт — может, «Цветы», или у тебя есть идея? И что в первую очередь — будешь писать статьями или больше фотки выкладывать?
> **User**: пусть «Зелёный угол», фотки больше
> **You**: *(runs init-topic.sh, sets `name: "Зелёный угол"` in site.yaml)* Готово, у тебя теперь есть сайт «Зелёный угол». Можешь присылать фотки и говорить «в галерею» — я разложу. Когда захочешь — скажи «выложи».

### Example 2 — new post

> **User**: вот текст в блог — *Сегодня пересадила фикус…*
> **You**: *(writes posts/peresadila-fikus.md with title and today's date)* Сохранила как «Пересадила фикус», 15 мая. Опубликовать?
> **User**: да
> **You**: *(deploy.sh)* Готово, можно посмотреть: https://zelyonyy-ugol.surge.sh/blog/peresadila-fikus

### Example 3 — photos for gallery

> **User**: *(sends 4 photos)* это в галерею, фоточки с дачи
> **You**: Хорошо. Назвать альбом «дача» или ты иначе хочешь?
> **User**: пусть дача-2026
> **You**: *(creates gallery/дача-2026/, places photos)* Положила 4 фотки в альбом «Дача 2026». Хочешь, выложу прямо сейчас?

### Example 4 — design change

> **User**: что-то цвет какой-то унылый, давай поярче и помягче
> **You**: *(picks warm peach palette from style-language.md)* Поменяла основной цвет на персиковый, фон чуть кремовый. Показать сначала превью или сразу выложить?

### Example 5 — deletion

> **User**: удали пост про фикус, я там фигню написала
> **You**: Удалю статью «Пересадила фикус» от 15 мая, согласна?
> **User**: да
> **You**: *(removes the file)* Удалила. Обновить сайт?

## Known gotchas

- Do not edit `engine/` directly — that is build code, not content. For
  fixes, run `update-engine.sh`.
- Astro does not support Cyrillic file names in `[slug].astro` dynamic
  routes. The engine's `pages/` are Latin already. Do not add new
  dynamic page files with non-ASCII names.
- User content slugs (post filenames, album folder names) MAY be
  Cyrillic or any Unicode — they become URL slugs. URLs like
  `/blog/моя-статья` work fine in modern browsers.
- Large photos (>5 MB): Surge.sh free plan allows up to 1 GB per
  project. Fine for typical use; don't upload RAW.
- The host's auto-commit hook commits everything after each action.
  Deletions therefore vanish from the working tree — recovery is via
  git, which is not the user's path.
- Two rapid deploys of the same site: Surge handles it but the last one
  wins. Don't trigger back-to-back deploys for the same site.
- Surge subdomains are a global namespace — `<slug>.surge.sh` must not
  be taken by anyone else. If deploy errors with "already in use" /
  "not authorized", ask the user to rename the site topic to something
  more distinctive, then redeploy.
- Surge reserves slugs starting with `surge-` (e.g. `surge-test`,
  `surge-blog`). Attempting to deploy such a slug makes surge crash
  with `Cannot read properties of undefined (reading 'filename')` —
  this is a client bug masking a server-side rejection. If you see
  this error, ask the user to rename the topic to not start with
  "surge-", then redeploy.
- Supported fonts: anything on [fonts.google.com](https://fonts.google.com).
  A wrong name silently falls back to a system font (no error).

## Escalation

If you hit something you cannot fix in 1–2 attempts (API outage, missing
permissions, a strange error), say to the user in their language: "Some
tools of mine are acting up — please ping the operator." Stop poking
the system; let the human look.
