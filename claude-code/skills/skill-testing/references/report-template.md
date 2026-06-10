# Report Template (run / full modes)

The tables below are a render of the graders' JSON reports (see the schema
in grading.md). Mapping: `criteria[]` → Results Table rows (one column per
runner, `evidence` strings joined per row, journal-only verdicts marked
with their `evidence_kind`); `compliance[]` → Skill Compliance;
`references_read[]` → References read; `files_created[]` → evidence pool
for Outcome rows.

## Structure

```markdown
# Skill Test Report: {skill-name}

**Date:** {date}
**Skill path:** {path}
**Mode:** run | full
**Scenarios:** {count} (1 happy-path + {N} edge-cases)
**Runners per scenario:** 2 skill + 1 baseline
**Runs dir:** {/tmp/skill-tests/...} (ephemeral — evidence is quoted inline)

---

## Scenario: {name} ({type})

**Task:** {prompt text or summary}
**Persona modifications:** {none / list of changes}

### Results Table

| # | Criterion | Type | Runner 1 | Runner 2 | Baseline | Evidence |
|---|-----------|------|----------|----------|----------|----------|
| 1 | Asked about stack | Process | PASS | PASS | FAIL | R1: journal #3 `ASKED-USER "Какой стек?"`; R2: journal #2 same; BL: no ASKED-USER entry (journal-only) |
| 2 | Loaded patterns.md | Compliance | PASS | PASS | FAIL | R1: journal #5 `READ .../patterns.md`; R2: same; BL: went straight to coding (journal-only) |
| 3 | Tests before code | Process | PASS | FAIL | FAIL | R1: test_api.py created journal #7, api.py journal #9; R2: api.py journal #5, tests journal #8 (wrong order) |
| 4 | API file has handler | Outcome | PASS | PASS | FAIL | R1: api.py:12 `def handler(...)`; R2: api.py:14 same; BL: file missing |

Mark journal-only verdicts (evidence_kind = journal) — they are
self-reported and weaker than artifact evidence.

### Skill Compliance

| Phase | Runner 1 | Runner 2 | Baseline |
|-------|----------|----------|----------|
| 1. Preparation | YES | YES | skipped |
| 2. TDD | YES | partial | skipped |
| 3. Implementation | YES | YES | YES |
| 4. Self-Review | YES | NO | NO |

References read:
- patterns.md: R1 yes (journal #5), R2 yes, BL no
- architecture.md: R1 yes, R2 no, BL no

### Cross-Runner Consistency
Runner 1 and Runner 2 diverged on criterion #3 (TDD order) and phase 4
(Self-Review). Rule out answer-sheet divergence first (compare ASKED-USER
entries); if both runners assumed the same answers, this suggests the
skill's instruction is ambiguous. Specifically: [quote the ambiguous
instruction from the skill].

### Baseline Comparison
Criteria passed ONLY by skill-runners (skill adds value):
- #1 (asked about stack), #2 (loaded patterns), #4 (self-review)

Criteria passed by ALL (skill doesn't help — or sheet-assisted):
- #3 (tests before code) — sheet-assisted: the answer sheet mentioned
  testing expectations, so the baseline had the hint too

Criteria failed by ALL:
- none

---

(repeat for each scenario)

---

## Overall Analysis

### Skill Value
The skill improves {X} out of {Y} criteria compared to baseline.
Key improvements: {list the most impactful criteria the skill helps with}.

### Skill Issues
Problems found (criteria failed by ALL skill-runners):
1. **{Issue}**: Criterion "{criterion text}" failed by both runners.
   - Root cause: Skill instruction at line {N}: "{quote instruction}"
   - The instruction is {vague / missing / contradictory / too complex}
   - Suggested fix: Change "{old text}" to "{new text}" in SKILL.md line {N}

### Ambiguities
Where runners diverged (one passed, one failed):
1. **{Criterion}**: Runner 1 passed, Runner 2 failed.
   - Relevant instruction: "{quote}"
   - Why it's ambiguous: {explanation}
   - Suggested clarification: {specific text change}

## Verdict: {Ready / Needs Fixes / Broken}

**Ready** — all key criteria pass consistently, skill adds clear value.
**Needs Fixes** — some criteria fail, but fixable with specific changes.
**Broken** — fundamental issues, major rewrite needed.

## Recommendations

Priority-ordered list of fixes:
1. **[High]** Fix: {what} — Where: {file:line} — Why: {evidence}
   Before: "{current text}"
   After: "{suggested text}"
2. **[Medium]** ...
3. **[Low]** ...
```
