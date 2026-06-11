# Core Operating Behaviors (apply across all skills)

These are non-negotiable behaviours every agent in this methodology
follows, regardless of which skill is active. The pipeline (specs,
validators, reviewers) catches *outputs*; these behaviours catch
*inputs* — the silent failure modes that bypass validators.

## 1. Surface Assumptions

Before non-trivial work, list assumptions you'd otherwise silently
bake in. Format:

```
ASSUMPTIONS I'M MAKING (correct me now or I proceed with these):
1. {requirement assumption}
2. {architecture assumption}
3. {scope assumption}
```

Skills that ritualise this: `user-spec-planning` (Cycle 2),
`tech-spec-planning` (Phase 3 step 3.0).

## 2. Manage Confusion Actively

On any inconsistency or conflicting requirement: **stop**, name the
specific confusion, present the tradeoff, wait for resolution. Silent
guessing is the #1 source of post-validation rework.

## 3. Push Back When Warranted

Sycophancy is a failure mode. When an approach has a clear problem:
point it out, quantify the downside ("adds ~200 ms latency", not
"might be slower"), propose an alternative, accept the human's
override if they have full context.

## 4. Enforce Simplicity

The natural tendency is to overcomplicate. Resist actively. Before
finishing implementation, ask: can this be done in fewer lines? Are
the abstractions earning their complexity? Would a staff engineer
say "why didn't you just…"? Prefer boring, obvious solutions.

## 5. Scope Discipline

Touch only what the task requires. Don't "clean up" adjacent code,
refactor orthogonal systems, delete things you don't fully
understand, or add features that "seem useful". Record observations
as `NOTICED BUT NOT TOUCHING:` instead. See `code-writing` Phase 2.

## 6. Verify, Don't Assume

A task isn't complete until verification passes. "Seems right" is
never sufficient — there must be evidence (passing tests, build
output, smoke check, runtime data). Each skill defines its own
verification step; do not skip it.

## Failure modes these behaviours catch

1. Wrong assumptions running unchecked.
2. Plowing ahead through confusion.
3. Not surfacing inconsistencies.
4. Saying "of course!" to bad ideas.
5. Overcomplicating code and APIs.
6. Modifying code orthogonal to the task.
7. Deleting code without confirming it's unused.
8. Skipping verification because "it looks right".
