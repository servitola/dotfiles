---
name: feature-execution
description: |
  Orchestrate feature delivery as team lead: spawn agents by wave,
  manage review cycles (max 3 rounds), commit per wave.

  Use when: "выполни фичу", "do feature", "execute feature", "запусти фичу",
  "выполни все задачи", "execute all tasks"
---

# Feature Execution

Team lead orchestrates feature delivery. You are a dispatcher: spawn agents, track progress, commit code, escalate issues. Delegate all code reading, diff analysis, and report review to spawned agents. Your only inputs are status messages from teammates ("Task complete") and escalation requests.

## Phase 1: Initialization

0. Check `work/{feature}/logs/checkpoint.yml`:
   - `last_completed_wave > 0` → this is a resume after context compaction.
     Read checkpoint, then read `work/{feature}/decisions.md` to confirm what was actually completed.
     For tasks in the resumed wave: if a task has a decisions.md entry, it completed — update its
     frontmatter to `done` and skip it. Only re-execute tasks without a decisions.md entry.
     Check if `~/.claude/teams/{team_name}/config.json` exists: if yes, team is alive; if no,
     recreate via TeamCreate. Skip to Phase 2 starting from `next_wave`.
     Report to user: "Resuming from wave {N}. Waves 1-{N-1} completed."
   - `last_completed_wave: 0` → fresh start, proceed below.

1. Read `work/{feature}/tech-spec.md` and `work/{feature}/user-spec.md`
2. Read frontmatter of all task files in `work/{feature}/tasks/` — extract fields:

   | Field | Purpose |
   |-------|---------|
   | `status` | planned → in_progress → done |
   | `wave` | Parallel execution group number |
   | `depends_on` | Task numbers that must be done first |
   | `skills` | Skills the teammate loads |
   | `reviewers` | Reviewer agents to spawn (source of truth) |
   | `teammate_name` | Agent name for team spawning (optional) |
   | `verify` | Verification types: [smoke], [user], [smoke, user], or [] (optional) |

   Build waves: group tasks by `wave` field. Within a wave, all tasks run in parallel.

3. Build execution plan following template at `~/.claude/shared/work-templates/execution-plan.md.template`
4. Save to `work/{feature}/logs/execution-plan.md`
5. Show plan to user, wait for approval
6. Create team via TeamCreate
7. Update `work/{feature}/logs/checkpoint.yml`: set `total_waves` from the execution plan.

**Checkpoint:** execution plan approved, team created, checkpoint initialized.

## Phase 2: Execute Wave

1. Find tasks for current wave: `status: planned`, all `depends_on` tasks are `done`
2. Update frontmatter: `status: planned` → `status: in_progress`
3. For each task, spawn **teammate + reviewers** (if task has reviewers):

   Use `teammate_name` from task frontmatter as the agent name. If not set — pick a descriptive name based on the task.

   **Teammate** — `subagent_type: "general-purpose"`, `model: "opus"`, `team_name: "{team}"`

   Prompt template:

   ```
   You are "{name}" executing task {N}.

   Read task: {feature_dir}/tasks/{N}.md
   Load skills listed in task frontmatter. Follow the loaded skill workflow.

   If the task requires user actions — send the instruction to team lead via SendMessage.
   Team lead will forward to user and return confirmation.

   {reviewers_block}

   After task complete:
   - Write entry to {feature_dir}/decisions.md (follow template at ~/.claude/shared/work-templates/decisions.md.template).
     Summary: 1-3 sentences describing what was done and key decisions. Link JSON reports for review details.
   - Message team lead: "Task {N} complete. decisions.md updated."

   Feature dir: {feature_dir}
   ```

   **{reviewers_block}** — include only when task has reviewers (not `reviewers: none`):

   ```
   Your reviewers: {reviewer_names} (list of teammate names).

   Review process — after task is complete, follow this review process (overrides review steps from loaded skills):
   1. Run `git diff -- <your files>` and collect the list of changed files + full diff output.
   2. Send each reviewer via SendMessage: list of changed files + full diff output.
   3. Reviewers will perform review, write JSON report to `{feature_dir}/logs/working/task-{N}/{reviewer_name}-round{round}.json`, and send report path back to you.
   4. Read reports, fix findings. After fixes: send updated diff to reviewers for next round.
   5. Max 3 review rounds. Reason: diminishing returns — if 3 rounds cannot resolve findings, the issue requires human judgment. If unresolved after 3 → message team lead to escalate.

   Commit flow:
   1. After implementation complete (tests pass): git commit `feat|fix: task {N} — {brief description}`
   2. Send diff to reviewers for review.
   3. After each round of fixes (tests pass): git commit `fix: address review round {M} for task {N}`
   4. After all reviews pass (or max 3 rounds): git commit review reports with message `chore: review reports for task {N}`
   ```

   If task has `reviewers: none` — skip reviewer spawning. The teammate works independently, commits code with message `feat|fix: task {N} — {brief description}` (tests pass), and reports completion directly to team lead.

   **Each reviewer** (when present) — `subagent_type: "{reviewer_agent}"`, `model: "sonnet"`, `team_name: "{team}"`

   Prompt template:

   ```
   You are reviewer "{name}" for task {N}.

   Read specs: {feature_dir}/user-spec.md, {feature_dir}/tech-spec.md
   Read task: {feature_dir}/tasks/{N}.md

   Wait for a message from teammate "{teammate_name}" with git diff of changes.

   When you receive it:
   1. Perform your review based on the changed files list and diff provided
   2. Write JSON report to: {feature_dir}/logs/working/task-{N}/{reviewer_name}-round{round}.json
   3. Send report path to teammate "{teammate_name}" via SendMessage

   The teammate may send updated diffs for subsequent rounds (max 3).
   Review each round the same way. After the final round, shut down.
   ```

4. All agents work in parallel. Lead waits for teammates to report "Task complete."

### Audit Wave tasks

Audit Wave tasks (Code Audit, Security Audit, Test Audit) have `reviewers: none` — each auditor teammate IS the review. Spawn them as standard teammates (general-purpose, opus), each loads its methodology skill.

Each auditor:
- Reads decisions.md to understand what was done in each task
- Reads all source files listed in tech-spec "Files to modify" across all implementation tasks
- Reviews the final state of code holistically (full files, not diffs)
- Writes report to `{feature_dir}/logs/working/audit/{auditor-name}.json`
- Writes decisions.md entry, reports to lead

After all 3 reports:
- All clean → proceed to Final Wave
- Issues found → spawn a fixer teammate (ad-hoc, code-writing skill), assign the auditors who found issues as reviewers, standard review protocol (max 3 rounds). After approval → proceed to Final Wave. If unresolved after 3 rounds → escalate (see Escalation).

### Ad-hoc agents

When lead spawns an agent outside the original execution plan (to fix audit findings, handle escalations, complete missing work):

1. Lead assigns a skill and reviewers matching the type of work:
   - Code changes → skill: `code-writing`, reviewers: code-reviewer, security-auditor, test-reviewer
   - Prompt changes → skill: `prompt-master`, reviewers: prompt-reviewer
   - Skill changes → skill: `skill-master`, reviewers: skill-checker
   - Deploy/CI changes → skill: `deploy-pipeline`, reviewers: deploy-reviewer
   - Infrastructure changes → skill: `infrastructure-setup`, reviewers: infrastructure-reviewer, security-auditor
   - Other tasks (research, config, manual steps) → no skill, no reviewers. Agent follows lead's instructions directly.
2. The ad-hoc agent writes a decisions.md entry (same template as planned tasks)
3. Standard review protocol: agent commits → sends diff to reviewers → fix → max 3 rounds
4. Lead verifies decisions.md entry exists before considering ad-hoc work complete

**Checkpoint:** all teammates reported "Task complete", decisions.md entries written.

## Phase 3: Wave Transition

1. Verify decisions.md entries exist and match template (`~/.claude/shared/work-templates/decisions.md.template`)
2. If task had Smoke/User verification steps — confirm decisions.md Verification section includes results. Missing results without explanation → ask user whether to proceed.
3. Update task frontmatter: `status: in_progress` → `status: done`
4. Git commit: `chore: complete wave {N} — update task statuses and decisions`. Code is already committed by teammates.
5. Update `work/{feature}/logs/checkpoint.yml`: set `last_completed_wave`, update task statuses, set `next_wave`.
6. Next wave → Phase 2

**Checkpoint:** all wave tasks done, committed, checkpoint updated.

## Phase 4: User Review

All waves done including Final Wave (QA, deploy if applicable, post-deploy verification if applicable).

1. Show results: what was built, key decisions, QA report summary
2. Describe what to check manually (from execution plan "user checks" section)
3. Issues found → fix → review → commit (max 3 rounds). If unresolved → escalate (see Escalation).
4. All ok → finalize, shutdown team, delete `work/{feature}/logs/checkpoint.yml`

## Escalation

Call user when:
- 3 review/fix iterations exhausted with remaining findings
- Teammate reports blocker or ambiguous requirement
- Task depends on unavailable MCP tool or external service

When escalating:
1. Stop all work on the blocked task/wave
2. Report to user: what failed, what was tried (all 3 attempts), what remains unresolved
3. Write decisions.md entry: summary of attempts + unresolved findings
4. Git commit: `chore: escalate task {N} — unresolved after 3 fix rounds`
5. Wait for user decision before continuing

## Self-Verification

- [ ] Execution plan created and approved
- [ ] All tasks executed, reviewed where applicable (max 3 iterations each), decisions.md filled
- [ ] All waves committed (including Final Wave)
- [ ] User reviewed and approved
