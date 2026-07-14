# Python scaffold

Reference stack: **uv + hatchling (`src/` layout) + ruff + mypy strict + pytest**,
git hooks via the **pre-commit framework** split into pre-commit (fast) and pre-push
(tests). Modelled on the user's `serho` repo. Resolve latest-stable versions when
installing — the pins below are illustrative.

## Contents
- Layout
- pyproject.toml (build, ruff, mypy, pytest)
- .pre-commit-config.yaml (pre-commit / pre-push split)
- Tests: unit vs integration
- CI
- Install & verify

## Layout

```
src/<pkg>/__init__.py
tests/unit/
tests/integration/
scripts/check_file_length.py   # copied from the skill
pyproject.toml
.pre-commit-config.yaml
.gitleaks.toml
.gitignore  .env.example
.github/workflows/ci.yml
```

Create the package with `uv init --package` (or `uv init --lib`), then `uv add --dev`
the tooling so versions resolve to latest stable.

## pyproject.toml

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "<pkg>"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[dependency-groups]
dev = [
  "ruff>=0.13", "mypy>=1.18", "pytest>=8", "pytest-asyncio>=1.4",
  "pytest-cov>=5", "pre-commit>=4",
]

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
# Broad, opinionated select — matches the user's serho config.
select = ["E","F","I","N","UP","B","SIM","RUF","S","PLC","PLE","PLR","PLW",
          "C90","T20","PIE","RET","ARG","PTH","TRY","PERF"]
[tool.ruff.lint.mccabe]
max-complexity = 10
[tool.ruff.lint.pylint]
max-args = 8
[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101", "PLR2004", "ARG"]   # asserts & magic numbers are fine in tests

[tool.mypy]
strict = true
warn_unused_ignores = true
python_version = "3.12"

[tool.pytest.ini_options]
addopts = "--strict-markers -ra"
testpaths = ["tests"]
markers = ["integration: touches network/docker/external services (deselect with -m 'not integration')"]

[tool.codespell]
# Add false positives as they surface — keep this line commented until non-empty,
# an empty `ignore-words-list` makes codespell error on an empty -L argument:
# ignore-words-list = "ratatui,userA"
skip = "./.venv,./.git,./uv.lock,./.mypy_cache,./.ruff_cache,./.pytest_cache"
```

## .pre-commit-config.yaml

Two stages: a snappy commit loop (lint/format/secrets/file-length) and a heavier
pre-push (types + tests). Keeps commits fast without losing the gate.

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: check-added-large-files
        args: ["--maxkb=512"]
      - id: check-merge-conflict
      - id: check-yaml
      - id: check-toml
      - id: check-json
      - id: detect-private-key      # cheap second net alongside gitleaks
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.13.3
    hooks:
      - id: ruff-check       # `ruff` is a deprecated alias in recent ruff-pre-commit
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/codespell-project/codespell
    rev: v2.4.1
    hooks:
      - id: codespell        # typos in code, comments, docs — near-zero friction
        args: [--toml=pyproject.toml]
        additional_dependencies: [tomli]

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks

  - repo: local
    hooks:
      - id: file-length
        name: code files ≤ 100 lines of logic
        entry: python3 scripts/check_file_length.py
        language: system
        types_or: [python]

      - id: mypy
        name: mypy (strict)
        entry: uv run mypy src
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: pytest
        name: pytest (unit only)
        entry: uv run pytest -q -m "not integration"
        language: system
        pass_filenames: false
        stages: [pre-push]
```

### Graduation tier (opt-in — add as the repo matures, not on a fresh PoC)

The `serho` repo also runs `bandit`, `vulture` and `xenon`. They are deliberately
**left out of the default** because on a young PoC they mostly duplicate checks the
ruff config above already runs, or produce noise that needs babysitting. Add one when
its specific value appears — and know what you are turning on:

- **bandit** (security lint) — largely redundant here: ruff's `S` group is already in
  `select`. In serho, bandit even skips B101/B105/B404/B603/B606/B607 as duplicates and
  is kept only "to catch new categories". Add for a repo handling auth / secrets /
  subprocess where the marginal extra coverage is worth a second scanner.
  `args: [-q, -r, src/, -c, pyproject.toml]`, `[tool.bandit] skips = [...]`.
- **vulture** (dead-code finder) — powerful but noisy on immature code: it flags every
  unused function/argument, so it needs a curated `[tool.vulture] ignore_names` list
  (framework DI args, `cls`, dunder args) before it stops crying wolf. Add as a periodic
  audit on a stabilised codebase, not a day-one commit gate. `min_confidence = 80`.
- **xenon** (complexity ceiling) — overlaps the `C90` mccabe gate already configured
  (`max-complexity = 10`). Add only if you want a whole-module/average grade on top of
  per-function complexity. `args: [--max-absolute=E, --max-modules=D, src/]`.

Rule of thumb: reach for these when the PoC becomes a product, and turn on the one that
solves a problem you actually have.

## Tests: unit vs integration

- `tests/unit/` — pure, fast, no I/O. Runs on pre-push and in CI by default.
- `tests/integration/` — mark each with `@pytest.mark.integration` (docker /
  testcontainers / real network). Excluded from the fast loop; CI runs them in a
  separate step (`uv run pytest -m integration`).

Add a smoke test that imports the package so the scaffold is proven from line one.

## CI (.github/workflows/ci.yml)

```yaml
name: ci
on: { push: { branches: ["**"] }, pull_request: {} }
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
        with: { enable-cache: true }
      - run: uv sync --all-extras --dev --frozen
      - run: uv run pre-commit run --all-files
      - run: uv run mypy src
      - run: uv run pytest -q -m "not integration" --cov=src
      - run: uv run pytest -q -m integration     # separate step; may be allowed to be flaky early
      - run: |
          uv export --frozen --no-dev --format requirements-txt --no-hashes \
            | uv run pip-audit --strict --requirement /dev/stdin
```

## Install & verify

```bash
uv sync --dev
cp <skill>/scripts/check_file_length.py scripts/
uv run pre-commit install --install-hooks
uv run pre-commit install --hook-type pre-push
uv run pre-commit run --all-files          # must pass
python3 scripts/check_file_length.py --walk src
```
