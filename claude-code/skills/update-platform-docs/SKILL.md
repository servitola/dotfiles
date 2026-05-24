---
name: update-platform-docs
description: |
  Update cTrader platform documentation in the workbot-docs repo from AIR MCP sources.
  Reads articles from ~/projects/workbot-docs/platform/, checks source_ids
  in frontmatter, fetches fresh content via AIR MCP, and regenerates articles
  that have changed. Can also add new articles to existing categories.

  Use when: "обнови платформенные доки", "update platform docs",
  "обнови документацию платформы", "синхронизируй доки с MCP",
  "refresh platform documentation", "update workbot docs from MCP",
  "проверь актуальность доков", "update-platform-docs"
---

# Update Platform Documentation

Updates the cTrader platform documentation at `~/projects/workbot-docs/platform/`
(project-agnostic, shared across all projects) by fetching fresh content from
AIR MCP and regenerating changed articles.

## Prerequisites

- AIR MCP tools must be available (`mcp__air-api__search_ctrader_help_centre`, `mcp__air-api__fetch`)
- `workbot-docs` repo must exist at `~/projects/workbot-docs`

## Workflow

### Phase 0: Sync the docs repo

Always run first:

```sh
cd ~/projects/workbot-docs
git pull --ff-only
```

Stop and tell the user if the pull fails.

### Phase 1: Inventory

1. Read `~/projects/workbot-docs/platform/INDEX.md` to get the full article list.
2. For each article file, read the YAML frontmatter to extract:
   - `source_ids` — list of AIR MCP document IDs
   - `last_updated` — date of last update
3. Build an inventory: `{file_path, source_ids[], last_updated}` for all articles.
4. Report the inventory to the user: total articles, oldest update date, categories.

### Phase 2: Fetch and Compare

For each article (or a subset if user specified categories):

1. For each `source_id` in the article's frontmatter:
   - Call `mcp__air-api__fetch` with the source ID
   - If fetch fails (document removed/renamed), note it and continue
2. Compare the fetched content against the current article:
   - Look for new sections, changed rules, updated formulas, new constraints
   - Flag articles where source content has materially changed
3. Report to the user which articles need updating and what changed.

### Phase 3: Regenerate (with user approval)

For each article that needs updating:

1. Re-distill the fresh MCP content into developer-focused format:
   - Keep the same article structure (Summary, Key Concepts, Rules and Constraints, Data Model, Platform Behavior, Related Articles)
   - Remove marketing language, screenshots, UI navigation
   - Focus on: formulas, business rules, data models, edge cases
   - Preserve any manually-added content that wasn't from MCP sources
2. Update the `last_updated` field in frontmatter to today's date.
3. Write the updated article.

### Phase 4: Index Update

1. If new articles were added, update `platform/INDEX.md` with new entries.
2. If articles were removed (sources no longer exist), mark them in INDEX.md.
3. Report updated/added/unchanged/removed counts.

### Phase 5: Commit and optional push

```sh
cd ~/projects/workbot-docs
git add platform/
git commit -m "docs(platform): refresh from AIR MCP"
git push origin main   # optional — skip silently if no remote or push fails
```

Never use `git add -A` — stage only the files you actually changed.

## Article Format Reference

```markdown
---
source_ids:
  - "doc-source-path-1"
  - "doc-source-path-2"
last_updated: "YYYY-MM-DD"
---

# [Topic Title]

> **Relevance**: [When a developer needs this]
> **Source**: cTrader Help Centre / Admin Guide

## Summary
[2-3 sentences]

## Key Concepts
### [Concept]
[Developer-friendly definition]

## Rules and Constraints
- [Business rule affecting code]

## Data Model
| Field | Type | Description |

## Platform Behavior
[Edge cases, mobile-specific behavior]

## Related Articles
- [Link](../path.md) — reason
```

## Options

The user can specify:
- **Category filter**: "update only trading docs", "refresh copy-trading"
- **Full refresh**: "update all platform docs" — regenerates everything
- **Dry run**: "check what's changed" — only Phase 1-2, no writes
- **Add new**: "add article about [topic] to [category]" — creates new article from MCP search

## Notes

- Do NOT change the article structure or format — only update content.
- Preserve cross-references between articles (Related Articles section).
- If a `source_id` no longer returns content, keep the article but note it may be stale.
- Use parallel agents for bulk updates (up to 5 categories at once). Each agent edits files
  only — the main thread handles Phase 0 pull and Phase 5 commit/push.
- After updating, verify the INDEX.md keywords still match the updated content.
