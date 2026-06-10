# Grading: Orchestrator Contract

How to invoke `skill-test-grader` agents and interpret their output. The
grading methodology itself (evidence rules, verdicts) lives inside the
agent — `claude-code/agents/skill-test-grader.md`.

## Invocation contract

One `skill-test-grader` per runner, all spawned in one parallel wave after
every runner has finished. Pass in the Task prompt:

1. `sandbox path` — the runner's workspace
   (`/tmp/skill-tests/{skill}/{ts}/{scenario}/{runner-id}/`)
2. `scenario file path` — the scenario .md (criteria, grading notes)
3. `tested skill's SKILL.md path` — for the compliance check
4. `runner type` — `skill` or `baseline`
5. `runner id` — e.g. `happy-path/skill-1`

The grader reads the sandbox; you read only its JSON. Reason: sandboxes
are large — reading them yourself fills the orchestrator context that the
report compilation still needs.

## Grader output schema

```json
{
  "runner_id": "happy-path/skill-1",
  "runner_type": "skill",
  "criteria": [
    { "id": "C1", "category": "Outcome", "text": "...",
      "verdict": "PASS", "evidence": "api.py:12 `def handler(...)`",
      "evidence_kind": "artifact" }
  ],
  "compliance": [
    { "phase": "Phase 2", "followed": true, "evidence": "journal #4" }
  ],
  "references_read": [ { "path": "references/x.md", "evidence": "journal #2" } ],
  "files_created": [ "/tmp/skill-tests/.../api.py" ],
  "notes": "free-form observations (ambiguities, near-misses)"
}
```

`evidence_kind: artifact | journal` — shows the share of journal-only
verdicts (journal is self-reported, weaker evidence). Keep this schema in
sync with the agent body; when it changes, update the JSON→table mapping in
report-template.md as well.

## Baseline comparison (quadrant analysis)

Per criterion, compare skill-runners vs baseline:

- Passed by skill-runners ONLY → skill adds value
- Passed by ALL → criterion too easy or skill doesn't help.
  Sheet-contamination check first: before declaring the criterion too easy,
  check whether the baseline succeeded thanks to information leaked via the
  persona answer sheet (the sheet is derived from the skill's dialogue
  points); if so, note "sheet-assisted" instead of "too easy".
- Failed by ALL → criterion may be unrealistic, or the skill is broken
- Passed by baseline ONLY → skill might be harmful

## Cross-runner consistency

Where the two skill-runners diverged (one PASS, one FAIL) → likely an
ambiguity in the skill; quote the ambiguous instruction in the report.
First rule out divergence caused by different assumed answers or approval
handling: compare the `ASKED-USER` entries in both graders' JSON (and the
journals they cite) — if the runners assumed different answers, the
divergence belongs to the answer sheet, not the skill.
