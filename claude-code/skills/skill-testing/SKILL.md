---
name: skill-testing
description: |
  Tests Claude Code skills end to end: designs test scenarios, executes
  them via parallel subagent runners against a no-skill baseline, grades
  acceptance criteria on evidence, and reports. Modes: quick smoke test
  (default, no interview), scenario design only, run existing scenarios,
  full A/B cycle with baseline and graders.

  Use when: "протестируй скилл", "проверь скилл тестами", "smoke test
  skill" (quick); "придумай тесты для скилла", "спроектируй сценарии
  тестирования", "design skill test scenarios" (design only); "прогони
  сценарии скилла", "запусти тесты скилла", "run skill test scenarios"
  (run existing); "полный тест скилла", "A/B тест скилла с baseline",
  "full A/B skill test" (full cycle).
---

# Skill Testing

Test skills by running them in isolated subagent workspaces against a
no-skill baseline and grading the evidence. You are designer, orchestrator,
and report compiler — runners are Task subagents, graders are the dedicated
`skill-test-grader` agent.

## Mode Selection

| Mode | What it does | Cost |
|---|---|---|
| **quick** (default) | Smoke test, no interview: auto-derived scenario, 1 skill-runner + 1 baseline, 2 graders, short verdict in chat | interaction: zero questions (except the side-effect gate); wall-clock: minutes for light skills, tens of minutes for heavy procedural ones; context: comparable to full (complete read of the tested skill + 3 references) |
| **design** | Interview (one consolidated proposal, not six sequential questions) → scenario files on disk | medium |
| **run** | Execute existing scenarios: 2 skill-runners + 1 baseline per scenario, graders, full report file | heavy |
| **full** | design → run in one session | heavy |

Default to quick when the user just says «протестируй скилл X». Switch to
full only on explicit request (baseline, A/B, «полный»). If scenarios
already exist at `~/.claude/skill-tests/{skill}/scenarios/` and the user
says «прогони/запусти» — mode run. Quick saves interaction (no interview,
no report file); wall-clock depends on how heavy the tested skill is, and
context cost is comparable to full.

## Phase 0: Understand the Target Skill

Common to all modes.

1. Resolve skill path: `~/projects/dotfiles/claude-code/skills/{name}/`;
   fallback — project-level `.claude/skills/{name}/` of the current project.
2. Read SKILL.md + all referenced files completely.
3. Map: skill type (procedural / informational / dialogue / one-shot),
   inputs, outputs, phases + approval checkpoints (feeds the answer sheet's
   assumed-approval rule), references agents must read, decision points,
   dialogue points, side-effect paths — both absolute and relative writes.
4. Classify side effects: sandbox-safe (files only) / system (cron,
   launchctl, git) / external-irreversible (logged-in web sessions,
   payments, messages, deploys). External/irreversible → raise the
   side-effect flag.

**Checkpoint:** map built. Design/full — presented to user. Quick — kept
internal, except the side-effect flag: if raised, stop and confirm with the
user before spawning any runner (see the gate in the Quick mode below).
Reason: the forbidden-actions list given to runners is prompt-enforced and
does not cover reversible-but-unwanted actions inside live logged-in
accounts (cart filling, booking flows) — a human decides, not a default.

## Mode: Quick (default)

1. Auto-derive one happy-path scenario from the map: the most common
   request the skill's own description triggers on. Build the task prompt +
   persona answer sheet (default persona + sheet rules) and 5-8 acceptance
   criteria per the criterion quality rules — both from
   [scenario-format.md](references/scenario-format.md).
2. Side-effect gate: if Phase 0 raised the flag — present it with the plan:
   "{skill} drives a logged-in {service} session / installs system state.
   Runners get the forbidden-actions list, but it is prompt-enforced and
   does not cover reversible actions inside live accounts (cart filling,
   booking flows). Proceed with quick / switch to design (per-scenario
   side-effects policy) / cancel?" Wait for the answer. No flag → proceed
   silently.
3. Write the scenario into
   `/tmp/skill-tests/{skill}/{YYYYMMDD-HHmm}/quick/scenario.md`
   (traceability, same format as designed scenarios).
4. Spawn in parallel: 1 skill-runner + 1 baseline using the prompt
   templates from [runner-prompts.md](references/runner-prompts.md).
5. Spawn 2 `skill-test-grader` agents in parallel per the contract in
   [grading.md](references/grading.md).
6. Print the quick verdict (template below). No report file, no interview.

**Checkpoint:** both runners graded, verdict shown.

Quick verdict template:

```
## Quick verdict: {skill-name}
Scenario: {one line}
Skill runner: {X}/{N} criteria PASS · Baseline: {Y}/{N}
Skill adds value on: {criteria passed only with skill}
Issues: {failed criteria with one-line root cause each, or "none"}
Next: {«looks healthy» | «run full A/B test» | «fix SKILL.md line N first»}
```

## Mode: Design

1. Present the Phase 0 map to the user (including the side-effect
   classification): "Here's what I found in the skill: [summary]. What do
   you want to focus on?"
2. Single consolidated proposal — one message containing:
   - scope assumption (whole skill end-to-end unless the user narrows it);
   - 1 happy-path + 2-3 edge cases, each with WHY it tests an important
     aspect. Typical edge cases: ambiguous input («ну сделай что-нибудь»),
     missing context, contradictory requirements mid-dialogue, unusually
     large or small scope, input that triggers rarely-used branches;
   - draft task prompts (natural, exactly what a user would type);
   - draft acceptance criteria per scenario;
   - draft persona answer sheets, including assumed-approval points;
   - side-effects policy per scenario, with the same external/irreversible
     warning text as the quick gate when the flag is raised.
   User adjusts in one round; iterate only on the changed parts.
3. Save each scenario to `~/.claude/skill-tests/{skill}/scenarios/{name}.md`
   following the template in
   [scenario-format.md](references/scenario-format.md); supporting files
   (task files, mock data) go next to it. Scenario files are git-tracked
   durable assets — offer to commit them.

**Checkpoint:** user approved the final set; files saved; paths confirmed.
Close with: "Run them now or later with «прогони сценарии {skill}»."

## Mode: Run

1. Read all scenario files from
   `~/.claude/skill-tests/{skill}/scenarios/`. None found → offer design
   mode. Old-format scenarios: missing Persona Answer Sheet → generate the
   sheet from the Persona block; a "Model for this test" field → ignore it
   (runners inherit the orchestrator's model).
2. Plan to user: "{N} scenarios × (2 skill-runners + 1 baseline) = {M}
   runners. {Side-effect flag from Phase 0, if raised.} Proceed?"
   **Checkpoint:** confirmed.
3. Spawn all runners across all scenarios in one parallel wave (cap 6
   concurrent; overflow goes in a second wave), prompts per
   [runner-prompts.md](references/runner-prompts.md). Sandboxes under
   `/tmp/skill-tests/{skill}/{YYYYMMDD-HHmm}/`.
4. Spawn one `skill-test-grader` per runner in a parallel wave per
   [grading.md](references/grading.md).
5. Compile from the graders' JSON outputs only — graders read the
   sandboxes, you keep your context clean:
   - results table criteria × runners;
   - cross-runner consistency: two skill-runners diverged → ambiguity in
     the skill, quote the instruction; on approval points first compare the
     `ASKED-USER` journal entries — did both apply assumed approval?
   - baseline quadrant analysis with the sheet-contamination check.
6. Write the report following
   [report-template.md](references/report-template.md) to
   `~/.claude/skill-tests/{skill}/reports/{timestamp}-report.md`
   (gitignored); show it to the user.

**Checkpoint:** every criterion graded with cited evidence; report saved
and shown.

## Mode: Full

Run Design (phases above), then immediately Run with the just-saved
scenarios. One user confirmation between them — the design checkpoint
doubles as the run plan confirmation.

## Final Check

- [ ] Target skill fully read (SKILL.md + all references)
- [ ] Mode matched the user's request (quick unless full/design/run was explicit)
- [ ] Side effects classified; external/irreversible → user confirmed before any runner spawned (all modes, including quick)
- [ ] Every runner had: workspace path + absolute-path instruction, journal instruction, persona answer sheet with assumed-approval rule, forbidden-actions list
- [ ] Graders (not the orchestrator) read the sandboxes
- [ ] Every criterion verdict cites evidence (artifact or journal entry)
- [ ] Baseline comparison done per criterion (with sheet-contamination check on passed-by-all)
- [ ] Quick → verdict in chat; Run/Full → report file saved and shown
- [ ] No runner artifacts left in the dotfiles repo (`git status` clean of test debris)
