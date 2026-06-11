---
name: methodology
description: |
  AI-First development methodology: spec-driven pipeline, project structure,
  skills/agents ecosystem, quality gates.

  Use when: "изучи методологию", "изучи глобальную папку", "как работает методология",
  "how does the methodology work", "explain the workflow"

  For infrastructure tasks, use infrastructure-setup or deploy-pipeline skills.
---

# AI-First Development Methodology

## What Is This

A structured development approach for AI agents. Every feature goes through a pipeline: idea → spec → architecture → tasks → implementation → documentation update. Each stage has automated validators and quality gates. QA and deploy are regular tasks in the tech-spec, not separate pipeline steps.

Core problems it solves:
- **Context loss between sessions** — distributed knowledge base persists across sessions
- **Quality without human review** — automated validators at every stage
- **Scope creep** — specs approved before coding starts
- **Outdated agent knowledge** — Context7 MCP fetches current library docs

## Development Pipeline

The full path from idea to production. Each step has a command, a skill behind it, and validators:

| Step | Command | Output | Skill |
|------|---------|--------|-------|
| 1. User Spec | `/new-user-spec` | `work/{feature}/user-spec.md` (approved) | `user-spec-planning` |
| 2. Tech Spec | `/new-tech-spec` | `work/{feature}/tech-spec.md` (approved) | `tech-spec-planning` |
| 3. Task Decomposition | `/decompose-tech-spec` | `work/{feature}/tasks/*.md` (validated) | `task-decomposition` |
| 4. Implementation | `/do-task` or `/do-feature` | committed code + reviews | from task file / `feature-execution` |
| 5. Done | `/done` | PK updated, feature archived | `documentation-writing` |

Step 4 mode choice:
- **`/do-task`** — single task, manual control, debugging, iterating on one piece.
- **`/do-feature`** — multiple tasks ready, standard feature work, parallel execution via agent teams.

To run or explain any step, follow its process in [pipeline.md](references/pipeline.md) — per-step validators, commit points, iteration limits, wave mechanics, escalation rules, plus cross-cutting principles (commit strategy, validation counts, checkpoint recovery, Context7, just-in-time context).

## What Do You Need?

Run a pipeline step / explain how a stage works?
→ read [pipeline.md](references/pipeline.md) — steps 1–5 in detail + key principles

Find where docs, specs, tasks live (Project Knowledge, `work/{feature}/`, global `~/.claude/`)?
→ read [project-structure.md](references/project-structure.md)

Look up a skill, agent, or slash command by name or category?
→ read [ecosystem.md](references/ecosystem.md) — planning/execution/quality/meta skills, validators, reviewers, commands

Apply the cross-skill behavioural rules in detail (formats, failure modes)?
→ read [operating-behaviors.md](references/operating-behaviors.md)

Load the smallest set of references that fits the task.

## Core Operating Behaviors (apply across all skills)

Every agent in this methodology follows these, regardless of which skill is active. The pipeline (specs, validators, reviewers) catches *outputs*; these behaviours catch *inputs* — silent failure modes that bypass validators:

1. **Surface assumptions** — before non-trivial work, list assumptions explicitly so the user can correct them.
2. **Manage confusion actively** — on inconsistency: stop, name the confusion, present the tradeoff, wait for resolution.
3. **Push back when warranted** — point out clear problems, quantify the downside, propose an alternative.
4. **Enforce simplicity** — prefer boring, obvious solutions; abstractions earn their complexity.
5. **Scope discipline** — touch only what the task requires; record side-observations as `NOTICED BUT NOT TOUCHING:`.
6. **Verify, don't assume** — a task is complete only when verification evidence exists (tests, build output, smoke check).

When applying these during work, follow the formats and rules in [operating-behaviors.md](references/operating-behaviors.md) — assumption-listing format, which skills ritualise each behaviour, and the 8 failure modes they catch.

## Workflow Quick Start

**New project:**
`/init-project` → `/init-project-knowledge` (interview + fill all docs) → start features

**New feature:**
`/new-user-spec` → `/new-tech-spec` → `/decompose-tech-spec` → `/do-feature` or `/do-task` → `/done`

**Ad-hoc coding (no spec):**
`/write-code`

To understand how a specific skill works internally, read its SKILL.md directly.
