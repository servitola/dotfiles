---
name: llm-wiki
description: |
  Build and maintain a persistent, compounding knowledge base as interlinked markdown files (Karpathy's LLM Wiki pattern): ingest sources, create entity/concept pages, cross-reference, and query.

  Use when: "заведи вики знаний", "добавь источник в мою вики", "построй базу знаний", "спроси у моей вики", "build a knowledge base wiki", "ingest this into my wiki", "query my wiki"
---

# Karpathy's LLM Wiki

Build and maintain a persistent, compounding knowledge base as interlinked markdown files.
Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

Unlike traditional RAG (which rediscovers knowledge from scratch per query), the wiki
compiles knowledge once and keeps it current. Cross-references are already there.
Contradictions have already been flagged. Synthesis reflects everything ingested.

**Division of labor:** The human curates sources and directs analysis. The agent
summarizes, cross-references, files, and maintains consistency.

## Wiki Location

**Location:** Set via the `WIKI_PATH` environment variable.

If unset, defaults to `~/wiki`.

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"
```

The wiki is just a directory of markdown files — open it in Obsidian, VS Code, or
any editor. No database, no special tooling required.

## Architecture: Three Layers

```
wiki/
├── SCHEMA.md           # Conventions, structure rules, domain config
├── index.md            # Sectioned content catalog with one-line summaries
├── log.md              # Chronological action log (append-only, rotated yearly)
├── raw/                # Layer 1: Immutable source material
│   ├── articles/       # Web articles, clippings
│   ├── papers/         # PDFs, arxiv papers
│   ├── transcripts/    # Meeting notes, interviews
│   └── assets/         # Images, diagrams referenced by sources
├── entities/           # Layer 2: Entity pages (people, orgs, products, models)
├── concepts/           # Layer 2: Concept/topic pages
├── comparisons/        # Layer 2: Side-by-side analyses
└── queries/            # Layer 2: Filed query results worth keeping
```

**Layer 1 — Raw Sources:** Immutable. The agent reads but never modifies these.
**Layer 2 — The Wiki:** Agent-owned markdown files. Created, updated, and
cross-referenced by the agent.
**Layer 3 — The Schema:** `SCHEMA.md` defines structure, conventions, and tag taxonomy.

## Resuming an Existing Wiki (do this every session)

When the user has an existing wiki, always orient yourself before doing anything:

① **Read `SCHEMA.md`** — understand the domain, conventions, and tag taxonomy.
② **Read `index.md`** — learn what pages exist and their summaries.
③ **Scan recent `log.md`** — read the last 20-30 entries to understand recent activity.

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"
# Orientation reads at session start (use the Read tool):
#   Read "$WIKI/SCHEMA.md"
#   Read "$WIKI/index.md"
#   Read "$WIKI/log.md"  (last ~30 lines)
```

Only after orientation should you ingest, query, or lint. This prevents:
- Creating duplicate pages for entities that already exist
- Missing cross-references to existing content
- Contradicting the schema's conventions
- Repeating work already logged

For large wikis (100+ pages), also run a quick Grep for the topic
at hand before creating anything new.

## Operations

Each operation maps to one reference. Load the smallest set of references that fits the task.

Start a new wiki?
└─ Follow the initialization steps in [init.md](references/init.md) — directory
   setup, plus the SCHEMA.md / index.md / log.md templates.

Add a source (URL, file, pasted text)?
└─ Follow the ingest workflow in [ingest.md](references/ingest.md) — raw capture
   with drift detection, page create/update rules, cross-referencing, bulk ingest.

Answer a question from the wiki?
└─ Follow the query workflow in [query.md](references/query.md) — page lookup,
   synthesis with citations, filing valuable answers back.

Lint, audit, or health-check?
└─ Run the checks in [lint.md](references/lint.md) — orphans, broken wikilinks,
   frontmatter validation, source drift, contradictions, tag audit, log rotation.

Browse or sync via Obsidian (desktop or headless server)?
└─ Apply the setup in [obsidian.md](references/obsidian.md) — vault settings,
   Dataview, obsidian-headless with systemd.

## Working with the Wiki

### Searching

- **Find pages by content** — Grep for `transformer` over `$WIKI` with glob `*.md`
- **Find pages by filename** — Glob `*.md` under `$WIKI`
- **Find pages by tag** — Grep for `tags:.*alignment` over `$WIKI` with glob `*.md`
- **Recent activity** — Read the last ~20 lines of `$WIKI/log.md`

### Archiving

When content is fully superseded or the domain scope changes:
1. Create `_archive/` directory if it doesn't exist
2. Move the page to `_archive/` with its original path (e.g., `_archive/entities/old-page.md`)
3. Remove from `index.md`
4. Update any pages that linked to it — replace wikilink with plain text + "(archived)"
5. Log the archive action

## Pitfalls

- **Raw sources are immutable** — the agent reads `raw/` but corrections go in wiki pages.
- **Always orient first** — read SCHEMA + index + recent log before any operation in a new session.
  Skipping this causes duplicates and missed cross-references.
- **Always update index.md and log.md** — skipping this makes the wiki degrade. These are the
  navigational backbone.
- **Don't create pages for passing mentions** — follow the Page Thresholds in SCHEMA.md. A name
  appearing once in a footnote doesn't warrant an entity page.
- **Don't create pages without cross-references** — isolated pages are invisible. Every page must
  link to at least 2 other pages.
- **Frontmatter is required** — it enables search, filtering, and staleness detection.
- **Tags must come from the taxonomy** — freeform tags decay into noise. Add new tags to SCHEMA.md
  first, then use them.
- **Keep pages scannable** — a wiki page should be readable in 30 seconds. Split pages over
  200 lines. Move detailed analysis to dedicated deep-dive pages.
- **Ask before mass-updating** — if an ingest would touch 10+ existing pages, confirm
  the scope with the user first.
- **Rotate the log** — when log.md exceeds 500 entries, rename it `log-YYYY.md` and start fresh.
  The agent should check log size during lint.
- **Handle contradictions explicitly** — don't silently overwrite. Note both claims with dates,
  mark in frontmatter, flag for user review.

## Related Tools

[llm-wiki-compiler](https://github.com/atomicmemory/llm-wiki-compiler) is a Node.js CLI that
compiles sources into a concept wiki with the same Karpathy inspiration. It's Obsidian-compatible,
so users who want a scheduled/CLI-driven compile pipeline can point it at the same vault this
skill maintains. Trade-offs: it owns page generation (replaces the agent's judgment on page
creation) and is tuned for small corpora. Use this skill when you want agent-in-the-loop curation;
use llmwiki when you want batch compile of a source directory.
