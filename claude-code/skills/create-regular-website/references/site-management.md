# Site management — edits, deletions, status, engine

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
hard. Better to ask once. (The host's auto-commit hook commits
everything after each action; deletions therefore vanish from the
working tree — recovery is via git, which is not the user's path.)

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

## Engine updates

Triggers from user: "update the engine", "something is broken, fix it",
"the design is glitching":
```
bash ~/projects/dotfiles/claude-code/skills/create-regular-website/scripts/update-engine.sh "$PWD"
```

Refreshes the engine code without touching user content.

Engine gotchas:
- Do not edit `engine/` directly — that is build code, not content. For
  fixes, run `update-engine.sh`.
- Astro does not support Cyrillic file names in `[slug].astro` dynamic
  routes. The engine's `pages/` are Latin already. Do not add new
  dynamic page files with non-ASCII names.

## Multiple sites

If the user has several site topics, each is independent. Surge domain
= `<transliterated-topic-name>.surge.sh`. Each gets its own URL.
Deploying one does not affect others.
