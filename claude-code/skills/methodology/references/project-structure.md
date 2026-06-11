# Project Structure

## Project Knowledge — the Knowledge Base

All project documentation lives in `.claude/skills/project-knowledge/references/`. This is the single source of truth for everything about the project.

**4 core + optional files:**

| File | Content |
|------|---------|
| `project.md` | Purpose, audience, core features, scope |
| `architecture.md` | Tech stack, structure, dependencies, data model |
| `patterns.md` | Code conventions, git workflow, testing, business rules |
| `deployment.md` | Platform, env vars, CI/CD, monitoring |
| `ux-guidelines.md` | UI language, tone, domain glossary (optional) |

Features and roadmap live in the project backlog (external to PK).

**CLAUDE.md is minimal.** It contains only the project name, a reference to project-knowledge skill, methodology overview, and default branch. All real information lives in Project Knowledge files.

**`project-planning` skill** creates PK from scratch in new projects via interview (`/init-project-knowledge`).

**`documentation-writing` skill** manages existing PK: audits, updates, checks consistency. `/done` command uses it to update PK after feature completion.

## Work Items

```
work/{feature}/
├── user-spec.md          # Requirements (Russian, for human)
├── tech-spec.md          # Architecture (English, for agent)
├── decisions.md          # Decisions made during implementation
├── tasks/
│   ├── 1.md              # Atomic task files
│   ├── 2.md
│   └── 3.md
└── logs/                 # Working logs (interview, research, reviews)
```

Completed features are archived to `work/completed/{feature}/`.

## Global Structure `~/.claude/`

```
~/.claude/
├── skills/               # Skills (methodology, workflow, quality)
├── agents/               # Agents (validators, reviewers, creators)
├── commands/             # Slash commands
├── shared/               # Templates, scripts, interview plans
├── hooks/                # Automation hooks
└── CLAUDE.md             # Global instructions
```
