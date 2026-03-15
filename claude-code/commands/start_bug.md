---
description: Investigate a bug with TDD fix process
argument-hint: <describe the bug>
---

I have a bug: $ARGUMENTS

Before attempting ANY fix, do the following strictly in order:

1) Read the relevant source files and trace the code path to understand the root cause with evidence.
2) Write a failing test that reproduces the exact bug.
3) Run the test to confirm it fails.
4) Only then implement the minimal fix.
5) Run the test again to confirm it passes.
6) Run the full test suite to check for regressions.

Do NOT skip steps or guess at fixes. If you're unsure of the root cause after step 1, say so and ask me before proceeding.
