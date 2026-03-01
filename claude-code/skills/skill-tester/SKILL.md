---
name: skill-tester
description: |
  Execute test scenarios prepared by skill-test-designer. Spawns parallel
  runners with and without the skill, interacts as user persona, grades
  acceptance criteria, produces detailed test report.

  Use when: "запусти тесты для скилла", "run skill tests", "execute skill
  scenarios", "проверь скилл тестами"
---

# Skill Tester

Execute test scenarios prepared by skill-test-designer.
You are team lead, user actor, and grader — all in one.

## Input

Scenario files at: `~/.claude/skill-tests/{skill-name}/scenarios/`
If no scenarios found → tell user to run skill-test-designer first.

## Phase 1: Prepare

1. Read ALL scenario files from the scenarios directory
2. Read the target skill's SKILL.md + key references
   You need to deeply understand what the skill instructs agents to do:
   - Which phases must agents follow and in what order?
   - Which references must agents read?
   - What outputs must agents produce?
   - What checkpoints must agents hit?
3. Read the persona from scenarios (your acting role)
4. If anything is unclear — ask the user before proceeding

**Checkpoint:** You can list all scenarios, the skill's phases, required
references, expected outputs, and your persona. If any are unclear, resolve
before proceeding.

## Phase 2: Setup

1. TeamCreate(team_name="skill-test-{skill-name}")
2. Plan: per scenario = 2 runners with skill + 1 baseline without skill
3. Scenarios run sequentially. Runners within a scenario run in parallel.
4. Show plan to user: "I'll run {N} scenarios, {M} runners total.
   Model: {model from scenarios}. Proceed?"

**Checkpoint:** User confirmed the execution plan. Team created.

## Phase 3: Execute

For each scenario:

### 3a. Spawn runners
Spawn 2 runners that load the tested skill:
- Prompt = scenario's task prompt (natural, as user would write)
- Each runner: `Skill(skill="{tested-skill-name}")`
- Model: as specified in scenario file
- Use `run_in_background: true`

Spawn 1 baseline runner:
- Same task prompt
- Receives no skill to load
- Same model, same `run_in_background: true`

Save each runner's task_id from the spawn result. You need these to
retrieve full transcripts for grading.

### 3b. Interact as user
Runners will send you questions. Answer in character per the scenario's
persona. Rules:
- Stay in character: answer as the user would
- Be consistent: same question from different runners → same answer
- Answer naturally, as a real user would — without guidance toward any
  specific behavior
- Keep conversation purely about the task itself (the feature, the question,
  the request)
- Baseline runner may ask different questions (no skill to guide it) — this
  is expected, answer them too

### 3c. Grade via grader agents

When all 3 runners finish, DO NOT read transcripts yourself — they are too
large and will fill your context. Instead, spawn grader agents (one per
runner) that read transcripts and return structured evaluations.

For each runner, spawn a grader via Task (not a team member, just a
subagent). Each grader receives:

1. The runner's task_id (grader calls `TaskOutput(task_id)` to get the full
   transcript with every tool call: Read, Grep, Write, WebFetch, Bash, Skill)
2. The scenario's acceptance criteria (copy the criteria list into the prompt)
3. The skill's SKILL.md path (grader reads it for compliance check)
4. Whether this is a skill-runner or baseline

Grader returns a structured evaluation:

```
## Acceptance Criteria
| # | Criterion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | WebFetch  | PASS    | "Tool call #3: WebFetch(url='https://...')" |
| 2 | Read INDEX| PASS    | "Tool call #7: Read('vault/knowledge/INDEX.md')" |

## Skill Compliance
| Phase | Executed | Evidence |
|-------|----------|----------|
| 1. WebFetch | YES | call #3 |
| 2. Topic routing | YES | call #7: Read INDEX.md |

## References Read
- TAGS.md: YES (call #9)
- notes.md: NO (never read)

## Files Created
- vault/knowledge/example.md — frontmatter: {type, tags, source, created}
```

Grader rules (include in grader prompt):
- **PASS** requires clear evidence: a specific tool call, file content, or
  message. Quote it directly.
- **FAIL** when no evidence found, evidence contradicts criterion, or only
  surface compliance (correct format, wrong substance).
- **When uncertain: FAIL.** Burden of proof is on the criterion.
- For process criteria: cite specific tool calls with arguments
- For outcome criteria: cite file content (read the created files)
- For compliance criteria: cite Bash calls for scripts

Spawn all 3 graders in parallel (one per runner). Wait for all to return.

### 3d. Compile results

You now have 3 structured evaluations (one per runner). Do NOT re-read
transcripts. Using only the grader outputs:

1. Build the results table (criteria × runners)
2. Cross-runner consistency: where did skill-runners diverge?
3. Baseline comparison:
   - Passed by skill-runners ONLY → skill adds value
   - Passed by ALL → criterion too easy or skill doesn't help
   - Failed by ALL → criterion may be unrealistic
   - Passed by baseline ONLY → skill might be harmful
4. Identify skill issues and ambiguities

### 3e. Cleanup
Shutdown all runners for this scenario.

## Phase 4: Report

Compile results from all scenarios following
[report-template.md](references/report-template.md).

Save to: `~/.claude/skill-tests/{skill-name}/reports/{timestamp}-report.md`
Show report to user.
TeamDelete.

## Self-Verification

- [ ] All scenarios executed (2 skill-runners + 1 baseline each)
- [ ] Grader agents used for transcript analysis (not read by lead directly)
- [ ] Every criterion graded with cited evidence from tool call transcripts
- [ ] Skill compliance checked for each runner
- [ ] Baseline comparison completed per criterion
- [ ] Report saved to expected path and shown to user
- [ ] Team deleted after report delivery
