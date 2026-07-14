# Extra stacks (Go / Rust / other)

Minimal-but-current toolchains for stacks the user hasn't standardised yet. Same
principles as the flagship references: newest-stable linters, a unit/integration
split, gitleaks, and the shared 100-logic-line file gate. Grow one of these into its
own full reference when a real repo adopts it.

## Generic hook wiring

Prefer the **pre-commit framework** (the user's default for non-mobile). The
file-length + gitleaks block is identical everywhere:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks: [{ id: gitleaks }]
  - repo: local
    hooks:
      - id: file-length
        name: code files ≤ 100 lines of logic
        entry: python3 scripts/check_file_length.py
        language: system
        types_or: [go, rust]     # narrow to the stack's file types
```

Add the stack's lint/format as `language: system` local hooks (below), tests on
`stages: [pre-push]`.

## Go

- Toolchain: `go vet` + **golangci-lint** (latest) + `gofumpt`. `go.mod` on the
  newest Go.
- `.golangci.yml`: enable `errcheck, govet, staticcheck, revive, gosec, gocyclo`
  (`gocyclo: min-complexity 12`).
- Tests: table-driven `*_test.go` for unit; integration tests behind a build tag
  `//go:build integration` — fast loop runs `go test ./...`, integration runs
  `go test -tags=integration ./...`.
- Hooks: `golangci-lint run`, `gofumpt -l -d .`, file-length on `*.go`.
- CI: `golangci-lint run` + `go test -race ./...` + tagged integration step.

## Rust

- Toolchain: `cargo fmt` + **clippy** with `-D warnings`. Pin via `rust-toolchain.toml`.
- `Cargo.toml` lints table or `#![deny(clippy::all, clippy::pedantic)]` at crate root
  (relax `pedantic` groups that fight a PoC).
- Tests: `#[cfg(test)]` unit modules; integration tests in `tests/` (each file is its
  own crate). `cargo test` runs both; gate integration behind a feature if they need
  external services.
- Hooks: `cargo fmt --check`, `cargo clippy -- -D warnings`, file-length on `*.rs`.
- CI: `cargo fmt --check` + `cargo clippy -- -D warnings` + `cargo test`.

## Anything else

For a stack with no reference here: pick the ecosystem's de-facto latest linter +
formatter + type/complexity checker, wire the same gitleaks + file-length pre-commit
block, split unit vs integration by the ecosystem's idiom, mirror it all in CI, and
note in the repo README which tools were chosen and why. Then consider promoting it
to a full reference in this skill.
