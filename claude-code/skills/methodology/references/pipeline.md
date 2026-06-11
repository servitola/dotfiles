# Development Pipeline — Step Details

The full path from idea to production. Each step has a command, a skill behind it, and validators.

## Table of Contents
- [Step 1: User Spec — `/new-user-spec`](#step-1-user-spec--new-user-spec)
- [Step 2: Tech Spec — `/new-tech-spec`](#step-2-tech-spec--new-tech-spec)
- [Step 3: Task Decomposition — `/decompose-tech-spec`](#step-3-task-decomposition--decompose-tech-spec)
- [Step 4: Implementation](#step-4-implementation)
- [Step 5: Done — `/done`](#step-5-done--done)
- [Key Principles](#key-principles)

## Step 1: User Spec — `/new-user-spec`

**What:** Structured interview to capture requirements in human-readable form (Russian).

**Process:**
- Agent reads Project Knowledge files to understand the project
- Scans codebase for relevant code, patterns, integration points
- Runs 3 interview cycles with the user (general → code-informed → edge cases)
- `interview-completeness-checker` agent verifies coverage
- Creates `user-spec.md` from interview data → git commit draft
- 2 validators run in parallel (up to 3 iterations):
  - `userspec-quality-validator` — document structure, acceptance criteria testability
  - `userspec-adequacy-validator` — solution feasibility, over/underengineering
- Git commit after each validation round
- User approves → git commit approval (status: approved)

**Output:** `work/{feature}/user-spec.md` (status: approved)

**Skill:** `user-spec-planning`

## Step 2: Tech Spec — `/new-tech-spec`

**What:** Technical architecture, decisions, testing strategy, implementation plan.

**Process:**
- Reads approved user-spec
- Researches codebase, checks dependencies, uses Context7 for external libraries
- Asks technical clarification questions
- Copies tech-spec template, edits sections in place → `tech-spec.md` with architecture (including Shared Resources for heavy objects like ML models, DB pools), decisions, testing strategy, brief Implementation Tasks (scope only — AC and TDD are added during task-decomposition) → git commit draft
- Implementation Tasks include Verify-smoke (executable checks: curl, python -c, docker) and Verify-user (manual UI/UX checks) fields where applicable
- Last two waves are always Audit Wave (3 parallel auditors: code, security, test) and Final Wave (QA + deploy)
- 5 validators run in parallel (up to 3 iterations):
  - `skeptic` — detects non-existent files, functions, APIs (mirages)
  - `completeness-validator` — bidirectional requirements traceability, over/underengineering, solution depth
  - `security-auditor` — OWASP Top 10 review
  - `test-reviewer` — test plan adequacy
  - `tech-spec-validator` — template compliance, task quality, wave conflict detection
- Git commit after each validation round
- User approves → git commit approval (status: approved)

**Output:** `work/{feature}/tech-spec.md` (status: approved)

**Skill:** `tech-spec-planning`

## Step 3: Task Decomposition — `/decompose-tech-spec`

**What:** Break tech-spec into atomic task files.

**Process:**
- For each Implementation Task in tech-spec, `task-creator` agent copies task template and fills it (parallel)
- Each task file expands brief tech-spec scope into: acceptance criteria, TDD anchor (from Testing Strategy), context files, skills, reviewers, wave, dependencies → git commit draft
- 2 validators run in parallel (up to 3 iterations):
  - `task-validator` — template compliance, content quality
  - `reality-checker` — validates against actual codebase (file existence, feasibility)
- Cross-task integration check: both validators re-run on all tasks together — catches shared resource conflicts, duplicate heavy resource init, hidden dependencies (max 2 extra iterations)
- Git commit after each validation round
- User approves → git commit approval

**Output:** `work/{feature}/tasks/*.md` (validated)

**Skill:** `task-decomposition`

## Step 4: Implementation

**Choose `/do-task` when:** single task, manual control, debugging, iterating on one piece.
**Choose `/do-feature` when:** multiple tasks ready, standard feature work, want parallel execution.

Two modes:

### Mode A: Single Task — `/do-task`

One task per session. Suited for manual, controlled execution.

**Process:**
- Reads task file and all its Context Files
- Loads skills specified in task (e.g. `code-writing`, `pre-deploy-qa`, `infrastructure-setup`)
- Follows loaded skill workflow (TDD for code tasks, verification for QA tasks, etc.)
- Git commit implementation (code + tests pass)
- Runs reviewers specified in task (if any), up to 3 review iterations
- Git commit after each round of review fixes (tests pass)
- Writes entry to `decisions.md`, updates task status → done
- Git commit status + decisions

**Skill:** Loaded from task file (typically `code-writing` for code tasks)

### Mode B: Full Feature — `/do-feature`

All tasks via agent teams. Team lead orchestrates waves of parallel work.

**Process:**
- Team lead reads tech-spec and all task files, builds execution plan
- Checks `checkpoint.yml` — if resuming after context compaction, skips completed waves (uses decisions.md as source of truth for what actually completed)
- Creates team via TeamCreate
- Executes tasks wave by wave:
  - Spawns one agent per task (parallel within wave)
  - Each teammate: follows loaded skill workflow, runs smoke verification if task has Verify-smoke (before reviews), commits code (tests pass), sends diff to reviewers, fixes findings with commits per round (max 3 rounds), commits review reports
  - Each teammate writes `decisions.md` entry
  - Lead commits status updates (task frontmatter + decisions.md) after wave completes, updates `checkpoint.yml`
- **Audit Wave** (always present): 3 auditors run in parallel (code-reviewer, security-auditor, test-reviewer) — review all feature code holistically. Issues found → lead spawns fixer agent, auditors become reviewers (max 3 fix rounds)
- **Ad-hoc agents**: when lead needs work outside planned tasks (fixing audit findings, escalations), assigns matching skill + reviewers based on work type
- **Final Wave**: QA (always), deploy + post-deploy (if applicable)
- **Escalation**: after 3 failed fix rounds — stop, report to user, write decisions.md entry, wait for decision
- User reviews results, team shuts down, `checkpoint.yml` deleted

Tasks can be code, user-action, deploy, config, or verification. Task nature is determined by its skill + description, not a separate type field.

**Skill:** `feature-execution`

## Step 5: Done — `/done`

**What:** Finalize feature, update project knowledge, archive.

**Process:**
- Reads user-spec, tech-spec, decisions.md
- Updates affected Project Knowledge files (architecture.md, patterns.md, deployment.md, etc.)
- Moves `work/{feature}/` → `work/completed/{feature}/`
- Commits changes

**Skill:** Loads `documentation-writing` skill for PK update rules

## Key Principles

### Commit Strategy
Commit after each step where the repository state is stable and meaningful. Not after every action — after each result.

- **Planning stages** (user-spec, tech-spec, tasks): draft commit → validation round commits → approval commit
- **Single task execution** (do-task): implementation commit (tests pass) → review fix commits (tests pass) → status/decisions commit
- **Feature execution** (do-feature): teammates commit code + review fixes, lead commits statuses per wave
- **Finalization** (done): single commit with PK updates + archive

### Spec-Driven Development
Write specifications before code. The hierarchy: User Spec → Tech Spec → Tasks → Code. Code starts only after specs are approved.

### Validation at Every Stage
- User spec: 2 validators (quality + adequacy)
- Tech spec: 5 validators (skeptic + completeness + security + test + template/task-quality)
- Tasks: 2 validators (template + reality)
- Code: 3 reviewers (code + test + security) + smoke verification (API calls, library checks, MCP tools, local runs)
- Audit Wave: 3 auditors (code + security + test) review all feature code holistically after implementation waves
- QA tasks: pre-deploy QA (tests + acceptance criteria), post-deploy QA (verification on live environment)

Max 3 fix iterations at each stage.

### Project Knowledge as Single Source of Truth
Project documentation = `.claude/skills/project-knowledge/references/`. CLAUDE.md stays minimal — just a pointer. The `/done` command updates PK after every feature. The `documentation-writing` skill audits PK for bloat and quality.

### Just-In-Time Context
Agent reads only what's needed for current task, not everything. Task files list their Context Files explicitly.

### Context7 for Library Docs
Agent uses Context7 MCP to fetch current library documentation instead of relying on training data. Used during tech-spec research and code implementation.

### Checkpoint Recovery
Feature execution persists state to `checkpoint.yml` after each wave. A `SessionStart(compact)` hook detects context compaction during long feature executions and injects recovery context — the lead resumes from the next pending wave using checkpoint + decisions.md as source of truth.
