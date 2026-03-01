# Report Template

## Structure

```markdown
# Skill Test Report: {skill-name}

**Date:** {date}
**Skill path:** {path}
**Model:** {model}
**Scenarios:** {count} (1 happy-path + {N} edge-cases)
**Runners per scenario:** 2 with skill + 1 baseline

---

## Scenario: {name} ({type})

**Task:** {prompt text or summary}
**Persona modifications:** {none / list of changes}

### Results Table

| # | Criterion | Type | Runner 1 | Runner 2 | Baseline | Evidence |
|---|-----------|------|----------|----------|----------|----------|
| 1 | Asked about stack | Process | PASS | PASS | FAIL | R1: "Какой стек предпочитаете?" msg #3; R2: "Что по технологиям?" msg #2; BL: did not ask |
| 2 | Loaded patterns.md | Compliance | PASS | PASS | FAIL | R1: Read tool call for patterns.md; R2: same; BL: went straight to coding |
| 3 | Tests before code | Process | PASS | FAIL | FAIL | R1: test_api.py created msg #7, api.py msg #9; R2: api.py msg #5, tests msg #8 (wrong order) |

### Skill Compliance

| Phase | Runner 1 | Runner 2 | Baseline |
|-------|----------|----------|----------|
| 1. Preparation | YES | YES | skipped |
| 2. TDD | YES | partial | skipped |
| 3. Implementation | YES | YES | YES |
| 4. Self-Review | YES | NO | NO |

References read:
- patterns.md: R1 yes, R2 yes, BL no
- architecture.md: R1 yes, R2 no, BL no

### Cross-Runner Consistency
Runner 1 and Runner 2 diverged on criterion #3 (TDD order) and phase 4
(Self-Review). This suggests the skill's TDD instruction may be ambiguous.
Specifically: [quote the ambiguous instruction from the skill].

### Baseline Comparison
Criteria passed ONLY by skill-runners (skill adds value):
- #1 (asked about stack), #2 (loaded patterns), #4 (self-review)

Criteria passed by ALL (skill doesn't help):
- #3 (tests before code) — even baseline sometimes writes tests first

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
