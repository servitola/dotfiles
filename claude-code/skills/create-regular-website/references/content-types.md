# Routing content — per-type flows

When the user sends text or a file, identify the type and place it.
If the intent is ambiguous, ask in **one short sentence** — do not
guess silently.

## Contents

- [Blog post](#blog-post)
- [Image attached to a post](#image-attached-to-a-post)
- [Photo album](#photo-album)
- [Portfolio project](#portfolio-project)
- [About page](#about-page)
- [Contacts and socials](#contacts-and-socials)
- [Design changes](#design-changes)
- [Naming and file gotchas](#naming-and-file-gotchas)

## Blog post

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

## Image attached to a post

If context is "for this post" / "to that article" — save as
`images/<post-slug>-<n>.jpg` and embed a markdown image link in the
post body. If context is unclear — ask.

## Photo album

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

## Portfolio project

Triggers: "here is my work", "this is for portfolio", "project X".

Create `projects/<slug>/` with:
```
projects/<slug>/
  description.md         (frontmatter: name, year, link)
  cover.jpg              (main image)
  images/                (additional shots, optional)
```

## About page

Triggers: "about me", "let me tell you about myself", "my bio".

Action: edit `about.md`. **Do not overwrite** existing text without
confirmation. Show a plan: "Right now it says 'X'. I will add 'Y',
rephrase 'Z'. Okay?" Then change.

## Contacts and socials

Triggers: "my Instagram", "Telegram", "email", "how to reach me".

Edit `links.yaml`. Confirm briefly afterwards: "Added Instagram and
Telegram, they will appear at the bottom of the site."

## Design changes

Look changes ("different color", "darker", fonts, "make it like this")
are routed from SKILL.md straight to
[style-language.md](style-language.md) — go there, not here.

Kept here:
- "Rename the site" → edit the site name in `site.yaml`.
- Supported fonts: anything on [fonts.google.com](https://fonts.google.com).
  A wrong name silently falls back to a system font (no error).

## Naming and file gotchas

- User content slugs (post filenames, album folder names) MAY be
  Cyrillic or any Unicode — they become URL slugs. URLs like
  `/blog/моя-статья` work fine in modern browsers.
- Large photos (>5 MB): Surge.sh free plan allows up to 1 GB per
  project. Fine for typical use; don't upload RAW.
