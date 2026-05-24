---
name: update-codebase-docs
description: |
  Update project codebase documentation in the workbot-docs repo from resolved YouTrack tickets.
  Fetches resolved tickets from the last N days for a given project (cTraderDev, mobileweb,
  jenkins-pipelines, jenkins-spotware-lib), clusters them by feature area, compares with
  existing articles, and updates/creates documentation based on new patterns, bugs, and
  implementations found in the project's source repository.

  Use when: "обнови кодовые доки", "update codebase docs",
  "обнови документацию по коду", "добавь новые тикеты в доки",
  "refresh codebase documentation", "update workbot codebase docs",
  "пополни доки из тикетов", "update-codebase-docs"
---

# Update Codebase Documentation

Updates per-project codebase documentation in the **workbot-docs** repository by analyzing
recently resolved YouTrack tickets and the corresponding code changes.

## Arguments

- `--project <key>` — which project to update (default: `cTraderDev`).
  Supported keys: `cTraderDev`, `mobileweb`, `jenkins-pipelines`, `jenkins-spotware-lib`.
- `--days <N>` — time window (default: 30).
- `--category <slug>` — only refresh a single category directory.
- `--dry-run` — only run Phase 1 (discovery), no writes.

## Paths

| Project | Source repo | Docs target |
|---|---|---|
| `cTraderDev` | `~/projects/Spotware/cTraderDev` | `~/projects/workbot-docs/projects/cTraderDev/codebase/` |
| `mobileweb` | `~/projects/Spotware/ctradermobileweb` | `~/projects/workbot-docs/projects/mobileweb/codebase/` |
| `jenkins-pipelines` | `~/projects/Spotware/CI/jenkins-pipelines` | `~/projects/workbot-docs/projects/jenkins-pipelines/codebase/` |
| `jenkins-spotware-lib` | `~/projects/Spotware/CI/jenkins-spotware-lib` | `~/projects/workbot-docs/projects/jenkins-spotware-lib/codebase/` |

Throughout the rest of this skill, `<docs>` means the chosen project's codebase directory
from the table above, and `<repo>` means the source repo.

## Prerequisites

- YouTrack MCP tools must be available (`mcp__youtrack-mcp-server__youtrack_search_issues`, etc.)
- Source repo `<repo>` must be accessible.
- `workbot-docs` repo must exist at `~/projects/workbot-docs`.
  If the target project's `codebase/` directory is empty, create `INDEX.md` as the first step.

## Workflow

### Phase 0: Sync the docs repo

Always run first, before any reads or writes:

```sh
cd ~/projects/workbot-docs
git pull --ff-only
```

If the pull fails (non-fast-forward, merge conflict), stop and tell the user — do not attempt
to rebase or force anything.

### Phase 1: Discover New Tickets

1. Search YouTrack for recently resolved tickets in the chosen project:
   ```
   project:WORKPROJ created:{minus Nd} .. today #Resolved sort by:updated desc
   ```
   (adjust the YouTrack project key if the target project has its own tracker)
2. Read existing articles in `<docs>/` and extract `based_on_tickets` frontmatter to build
   the set of already-documented ticket IDs.
3. Filter to only NEW tickets.
4. Cluster new tickets by area using summary tags (e.g., `[New Order]`, `[Chart]`). Match
   against existing category directories under `<docs>/`.
5. Report to user: N new tickets found, distributed across M categories.

If `--dry-run` is set, stop here.

### Phase 2: Analyze and Update

For each category with new tickets:

1. Fetch full ticket details via `youtrack_get_issues` (batch).
2. Read the existing article(s) for that category in `<docs>/<category>/`.
3. Decide what is genuinely new:
   - New bug patterns not yet documented?
   - New features that change the architecture?
   - New files or classes introduced?
   - New validation rules or business logic?
4. If significant new content exists:
   - Explore the relevant code in `<repo>/`.
   - Update the article with new sections, patterns, or bug entries.
   - Add new ticket IDs to `based_on_tickets` frontmatter.
   - Update `last_updated` date.

### Phase 3: New Categories

If new tickets don't fit any existing category:

1. Propose a new category name and directory.
2. Create the article following the standard format below.
3. Update `<docs>/INDEX.md` with the new entry.

### Phase 4: Commit and optional push

```sh
cd ~/projects/workbot-docs
git add projects/<project>/codebase/
git commit -m "docs(<project>): refresh codebase from tickets <range>"
git push origin main   # optional — skip silently if no remote or push fails
```

### Phase 5: Summary

Report:
- Articles updated (with what was added)
- New articles created
- Tickets that couldn't be categorized
- Total tickets now documented
- Commit hash and push status

## Article Format Reference

```markdown
---
based_on_tickets:
  - "WORKPROJ-XXXXX"
  - "WORKPROJ-YYYYY"
last_updated: "YYYY-MM-DD"
---

# [Feature Area]: [Title]

> **Relevance**: When you need this
> **Key files**: List of main files involved

## Architecture Overview
[How the feature is structured]

## Key Patterns
### [Pattern name]
[Description with file paths and code references]

## Common Bugs and Pitfalls
- [Bug pattern with explanation]

## Implementation Rules
- [Rule learned from implementations]

## Related
- [Cross-references]
```

## Parallelization

When updating multiple categories:
- Launch up to 5 agents in parallel, each handling one category.
- Each agent: fetches tickets → reads code → updates its article files (no git operations).
- Main thread: performs Phase 0 pull at the start and Phase 4 commit/push at the end,
  and updates INDEX.md after all agents complete.

## Notes

- Always ADD to existing articles, never remove content (unless it's factually wrong).
- Preserve the existing structure — add new entries under existing sections.
- New bug patterns go under "Common Bugs and Pitfalls".
- New implementation learnings go under "Implementation Rules".
- If a ticket reveals a pattern change, update "Architecture Overview" or "Key Patterns".
- Never use `git add -A` — stage only the files you actually changed.
