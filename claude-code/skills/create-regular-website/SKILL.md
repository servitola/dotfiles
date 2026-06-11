---
name: create-regular-website
description: |
  Creates and maintains a personal website for a non-technical user —
  blog, portfolio, gallery, landing page, or any mix. Content
  lives as files in the user's topic folder; the site publishes to
  Surge.sh (accessible from Russia without VPN).

  Trigger on initialization when the user says, in any language: "I want
  a website", "make me a site", "let's start a blog", "I want a
  portfolio", "personal page", "site about [topic]".

  Trigger on content work — only when the current folder contains
  `site.yaml`: "new post", "here is text/photos", "for the
  blog/gallery", "this is my work", "about me", "rename the site",
  "different color", "delete the post", "publish", "update the site",
  "show the link", "how does it look now".

  SKIP when: the folder has no `site.yaml` AND the user is not asking to
  create a site (e.g. "save this note somewhere"); the user asks how the
  site works technically (npm, deploy, git) — that is for the operator;
  the user wants a site for someone else (different topic/stack).
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

## Mode decision tree

Match the request to one branch and load only that reference — loading
every file costs the same as one giant skill and defeats the split.

No `site.yaml` in the folder, user asks for a site?
└─ Initialize following [references/initialization.md](references/initialization.md)
   — the two setup questions, running `scripts/init-topic.sh`,
   `site.yaml` name/lang setup, what gets scaffolded.

Folder has `site.yaml` — ongoing site work:

User sends content?
├─ Text / "new post" / "for the blog"
├─ Photos / "for the gallery" / "album"
├─ "Here is my work" / "for portfolio"
└─ "About me" / bio, "my Instagram" / socials
   → place it following the per-type flows in
     [references/content-types.md](references/content-types.md) —
     file locations, frontmatter, slugs, captions.

User asks for a look change — "different color" / "darker" / fonts /
"make it like this" (with screenshot)?
└─ Edit `site.yaml` (the `theme` section) following
   [references/style-language.md](references/style-language.md) —
   ready palettes, font pairings, single-axis tweaks, "like X"
   style references.

User asks to delete / rewrite / hide something, or "how many posts" /
"give me the link" / "update the engine"?
└─ Follow [references/site-management.md](references/site-management.md)
   — plan-and-confirm before destructive changes, hide vs delete,
   status reporting, engine updates, multiple sites.

User says "publish" / "update site" / "can I see it", or a deploy
just failed?
└─ Follow [references/publishing.md](references/publishing.md) —
   running `scripts/deploy.sh`, preview mode, sending the link and
   screenshot, deploy errors, Surge gotchas.

## Conversation principles

- **Describe actions in plain words**, not technical names. Not "I'm
  creating posts/plants.md", but "I'm saving your post about plants".
  Technical words distract them.
- **Confirm briefly after each action**: "Saved. The album now has 3
  photos." They need to see things working.
- **Before losing data — always plan + confirm**. See
  [references/site-management.md](references/site-management.md).
- **Ask one short question when ambiguous**, never silently guess. A
  one-line "is this for the blog or just to save?" is better than
  putting it in the wrong place.

For reply tone and phrasing, copy the patterns in
[references/example-dialogues.md](references/example-dialogues.md) —
init, new post, gallery, design change, and deletion dialogues.

## Voice messages

If audio arrives, it may come transcribed (Telegram bot can transcribe)
or as a file. If as a file, transcribe via available tools, then treat
the transcript as regular text from the user.

## Escalation

If you hit something you cannot fix in 1–2 attempts (API outage, missing
permissions, a strange error), say to the user in their language: "Some
tools of mine are acting up — please ping the operator." Stop poking
the system; let the human look.
