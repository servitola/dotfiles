# Harden an existing repo (Mode B)

Greenfield scaffolding (the other references) assumes an empty tree. An existing
repo already has code, history, and probably dozens of files over the line cap and a
partial toolchain. Blocking every violation on day one would wall off all work, so
harden with a **ratchet**: measure the current state, freeze it as a baseline, block
only regressions, and shrink the baseline over time.

## Workflow

1. **Audit.** Run `scripts/detect_stack.sh` and inventory what already exists: which
   linter/formatter/type-checker/test runner/hooks are present, their versions, and
   how far each is from that stack's reference. Produce a short gap list, not a rewrite.

2. **Adopt the toolchain non-destructively.** Add missing config (ruff/eslint/…,
   gitleaks, CI) using the stack reference, but tune severities so the first run is
   *green on legacy code*: enable autofix + formatter first, land that as one commit,
   then turn on stricter rules in follow-up commits. Never mass-reformat and change
   logic in the same commit — keep formatting commits separate and reviewable.

3. **Ratchet the file-length gate.** Existing oversized files must not block commits,
   but must not grow either:
   - Baseline them: `scripts/check_file_length.py --walk . --write-baseline .lengthbaseline`
     records every current violation (path + line count).
   - The hook then runs `--baseline .lengthbaseline`: a baselined file passes while it
     stays at or below its recorded count, and fails the moment it grows. Brand-new
     files get the full 100-line cap immediately.
   - Shrink the baseline as you split files; a file dropping under the cap is removed
     from it automatically on the next `--write-baseline`. The goal is an empty
     `.lengthbaseline`.

   (Until `--baseline` exists in the script, the interim tool is the per-file
   `project-init: allow-long` marker — but a baseline file is preferable because it is
   one auditable list instead of markers scattered across the codebase.)

4. **Secrets sweep.** Run `gitleaks detect` over the *full history*, not just the
   working tree — an existing repo may already have committed a secret. If it finds
   one, stop and tell the user (rotation + history rewrite is their call, not an
   automatic action).

5. **Backfill tests around the risk, not everything.** Do not chase coverage. Add the
   unit/integration split and a smoke test, then characterization tests for the areas
   about to change. Note honestly what is left untested.

6. **Land incrementally.** One concern per commit (add hooks; adopt formatter; enable
   type-checking; add CI; ratchet file-length), each green, so review and rollback stay
   easy. Update the repo README with the new `make`/`pre-commit` workflow.

## Checklist

- [ ] Gap list produced; user agrees on scope
- [ ] Formatter + autofix landed green as an isolated commit
- [ ] Stricter lint/type rules enabled in follow-up commits
- [ ] File-length ratchet in place; baseline recorded and shrinking
- [ ] gitleaks run over full history; findings surfaced to the user
- [ ] Unit/integration split + smoke test added
- [ ] CI mirrors local hooks; README documents the workflow
