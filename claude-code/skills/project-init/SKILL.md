---
name: project-init
description: |
  Scaffolds a fresh git repo (usually a proof-of-concept): detects the tech stack,
  installs the latest-stable linters / formatters / type-checkers, unit + integration
  tests, git hooks (secret scan + a ≤100-line-per-file gate), a CI workflow, then git
  init + a verified first commit.

  Use when: "сделай заготовку репозитория", "подготовь POC", "инициализируй проект",
  "настрой линтеры и хуки с нуля", "scaffold a repo", "bootstrap a project",
  "project-init", "set up a new repo with tests and hooks".
---

# Project Init

Turn a bare directory (or a rough proof-of-concept) into a rigorous git repo: the
stack is detected, the newest-stable toolchain is wired in, tests are split into
unit vs integration, git hooks block secrets and oversized files, and the whole
thing is verified before the first commit lands.

Load the smallest set of references that fits the detected stack — one per language.

## Two modes

- **Fresh repo (default)** — a bare dir or rough PoC. Follow the phases below.
- **Harden an existing repo** — the tree already has code, partial tooling, and files
  over the cap. Applying the full gate at once would wall off all work. Follow
  [harden-existing.md](references/harden-existing.md) — audit, adopt tooling
  non-destructively, and ratchet the file-length gate from a frozen baseline. Still
  read the matching stack reference for the target toolchain.

## Phase 0 — Detect the stack

Run the detector; it reads manifests first, then falls back to file extensions
for a manifest-less PoC:

```bash
scripts/detect_stack.sh <project-dir>
```

Read what actually sits in the directory (source layout, existing config, whether
it is a single PoC or a mini-monorepo). Confirm the detected stack(s) with the user
in one line, and ask two things only if unclear: is this a PoC or a real product
(affects how heavy CI should be), and for a monorepo — one shared toolchain or one
per package.

## Phase 1 — Route to the stack reference

Each reference lists the exact files to create, the newest-stable versions to
resolve, the hook wiring, and the unit/integration test split for that stack.

- **Python** → follow [python.md](references/python.md) — uv + hatchling `src/` layout, ruff (broad select) + mypy strict + pytest, pre-commit split into pre-commit/pre-push.
- **TypeScript / JS** → follow [typescript.md](references/typescript.md) — flat `eslint.config.ts` (airbnb + typescript-eslint + @stylistic), Jest + Playwright, granular-strict tsconfig, bleeding-edge deps.
- **.NET / C#** → follow [dotnet.md](references/dotnet.md) — `Directory.Build.props` (Nullable enable, wide WarningsAsErrors) + `.editorconfig` severities, xUnit unit/integration split.
- **Kotlin / Swift (mobile)** → follow [mobile.md](references/mobile.md) — ktlint + detekt / SwiftLint --strict + SwiftFormat, raw `.githooks/` + `core.hooksPath` wired via a Makefile.
- **Go / Rust or anything else** → follow [extra.md](references/extra.md) — minimal but current golangci-lint / clippy setups and the generic hook wiring.

Resolve the **latest stable** version of each tool at scaffold time (`uv add`,
`npm view <pkg> version`, `dotnet --version`, Gradle plugin portal), then pin what
you install. Reason: hardcoded versions rot; the user's real repos run bleeding-edge
(eslint 10, typescript 6, react 19, ruff 0.13+). Do not copy the version numbers in
the references verbatim — they are illustrative.

## Phase 2 — The file-length gate (every stack)

Copy `scripts/check_file_length.py` into the new repo (convention: `scripts/`) and
wire it into that stack's hook. It caps **logic lines at 100** for code and 300 for
tests, skips generated/vendored files, and honours a `project-init: allow-long`
escape marker. Each reference shows the exact hook entry.

This gate is the headline maintainability rule — small files force single-purpose
modules. It is non-negotiable across stacks; the 100 default may be tuned per repo
via `--limit`.

## Phase 3 — Secrets & ignore hygiene (every stack)

- Add `gitleaks` to the commit-time hook (`useDefault = true` + a `.gitleaks.toml`
  allowlist for fonts/binaries/branding assets).
- Write `.gitignore` (stack patterns + `.env`, `.env.*`, `!.env.example`, `*.key`,
  `*.pem`, `secrets/`) and a valueless `.env.example` if the project reads env vars.

**Checkpoint:** staging a file containing `AKIAZ7XQ4PWLK9RT2VBN` is blocked by the hook.
(Do not test with an `...EXAMPLE`-suffixed key — gitleaks' default config allowlists
the AWS documentation sample keys, so it would pass and give false confidence.)

## Phase 4 — CI

Mirror the local hooks in CI so nothing depends on a developer having installed the
hook. Keep it to the stack reference's workflow: run the full lint/format/type/test
gate on every push + PR. For a throwaway PoC a single lint+test job is enough; say so
rather than silently scaling it down.

## Phase 5 — git init, verify, first commit

1. `git init` (if not already a repo) and install the hooks (`pre-commit install
   --install-hooks && pre-commit install --hook-type pre-push`, or `make install-hooks`
   for the mobile `.githooks` pattern).
2. **Run the gates for real** — the lint/format/type/test command and the file-length
   gate over the tree (`scripts/check_file_length.py --walk .`). Fix what they flag.
   A green run is the proof the scaffold works, not an assumption.
3. Commit:
   ```
   chore: initialize project

   - Scaffold <stack> toolchain (lint, format, type-check)
   - Add unit + integration test setup
   - Wire git hooks (gitleaks + ≤100-line file gate)
   - Add CI workflow and .gitignore/.env.example
   ```
   Verify `git status` shows no `.env` (only `.env.example`) before committing.

## Final validation

- [ ] Stack detected and confirmed
- [ ] Latest-stable toolchain installed and pinned
- [ ] Lint / format / type-check command passes
- [ ] Unit and integration tests separated; both run
- [ ] File-length gate passes over the whole tree
- [ ] gitleaks blocks a test secret
- [ ] `.gitignore` covers `.env`, keys, secrets; `.env.example` present if needed
- [ ] CI workflow present and mirrors local hooks
- [ ] Hooks installed; first commit lands green
