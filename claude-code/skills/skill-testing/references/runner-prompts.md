# Runner Prompt Templates

## Spawn mechanics

- Task tool, `subagent_type: general-purpose`.
- All runners in one message for parallelism, cap 6 per wave (overflow goes
  in a second wave).
- Model is inherited from the orchestrator — Task calls have no model
  parameter. To test on a different model, start the whole testing session
  on that model.
- Runners cannot spawn subagents (one orchestration level). If the tested
  skill itself orchestrates subagents, note the limitation in the scenario
  and grade nested-agent criteria from artifacts.
- Sandbox path per runner:
  `/tmp/skill-tests/{skill}/{YYYYMMDD-HHmm}/{scenario}/{runner-id}/`
  (runner-id: `skill-1`, `skill-2`, `baseline`). Create the directory
  before spawning.

## Skill-runner template

Fill the placeholders, keep the section order:

```
You are a test runner executing a real task in an isolated workspace.

1. WORKSPACE
Treat `{sandbox abs path}` as your workspace. Write every artifact there.
Use absolute paths in every command and tool call; a tested skill that
uses relative paths would otherwise write into the orchestrator's repo —
prefix Bash commands with `cd {sandbox abs path} && ` to prevent this.
Your journal entry #1 confirms the workspace.

2. SKILL LOADING
<!-- active: primary (set at acceptance — flip to fallback if the Skill
     tool turns out to be unavailable to general-purpose subagents) -->
Primary: Invoke the Skill tool with skill="{skill-name}", then follow it
to complete the task below.
Fallback: Read `{skill path}/SKILL.md` completely, then follow it to
complete the task below.

3. TASK
{task prompt from the scenario, verbatim}

4. PERSONA ANSWER SHEET
You have no live user. When the skill tells you to ask the user something,
answer it yourself from this sheet, in character:
{answer sheet from the scenario}
Rules:
- (a) a question not covered by the sheet → make the most
  persona-consistent assumption and log it under "Assumed answers";
- (b) at any user-approval checkpoint ("present to user", "wait for
  confirmation") → assume approval and log
  `ASKED-USER "{checkpoint}" → assumed approval`.

5. JOURNAL
Keep `{sandbox abs path}/journal.md` — a numbered log of your actions.
Entry types:
- `READ {path}`
- `ASKED-USER "{q}" → answered from sheet / assumed: {a} / assumed approval`
- `DECIDED {what & why}`
- `WROTE {abs path}` (add `(redirected from {original path})` when redirected)
- `BLOCKED {cmd}`
The journal is the grader's only window into your process; an action
missing from the journal is graded as not having happened.

6. SIDE EFFECTS
Side-effects policy for this scenario: {redirect (default) |
allow-with-cleanup: {paths}}. Under redirect, any write the skill directs
outside your workspace — absolute or relative path — goes inside the
workspace instead, mirrored under the original path, and is journaled as
`WROTE {sandbox}{original-path} (redirected from {original-path})`.

Forbidden actions (always, regardless of policy): `crontab`/`launchctl`
install, `git push`, deploys, external form submissions/payments/emails/
external API writes, edits to any file outside your workspace. The skill
may instruct such actions — record the exact command as `BLOCKED {cmd}`
in the journal instead of executing. You are a test runner; irreversible
effects must not happen.

7. Finish with a 5-line summary of what you produced.
```

## Baseline template

Identical to the skill-runner template minus section 2 (skill loading).
In its place: "Solve the task using your general knowledge and built-in
tools only; do not load any skill." Reason: the baseline measures what the
skill adds — identical conditions except the skill itself.

The baseline receives the same persona answer sheet. The sheet contains
only persona facts (see the authoring rule in scenario-format.md), so it
informs both runners equally without leaking procedure.

## journal.md format

Numbered entries, one action per line:

```
1. READ /tmp/skill-tests/foo/.../journal.md workspace confirmed
2. READ ~/.claude/skills/foo/SKILL.md
3. ASKED-USER "Какой стек?" → answered from sheet: "что проще"
4. DECIDED single-file script, persona is not a programmer
5. WROTE /tmp/skill-tests/foo/.../api.py
6. ASKED-USER "Подтвердите план" → assumed approval
7. BLOCKED crontab -e (skill step 4 asks to install a cron job)
```
