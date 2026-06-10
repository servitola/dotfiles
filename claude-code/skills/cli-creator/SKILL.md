---
name: cli-creator
description: |
  Build a durable, composable CLI from API docs, an OpenAPI spec, curl examples, an SDK, a web app, or an existing script — installed on PATH, with stable JSON output, sane auth, and a companion skill so future agent threads can use it.

  Use when: "сделай CLI", "создай консольную утилиту", "оберни API в команду", "сделай из этого скрипта команду", "make a CLI tool", "build a command-line tool", "wrap this API in a CLI", "turn this script into a command"
---

# CLI Creator

Create a real CLI that future agent threads (Claude Code, Amp, Qwen) can run by command name from any working directory.

This skill is for durable tools, not one-off scripts. If a short script in the current repo solves the task, write the script there instead.

## Start

Name the target tool, its source, and the first real jobs it should do:

- Source: API docs, OpenAPI JSON, SDK docs, curl examples, browser app, existing internal script, or working shell history.
- Jobs: literal reads/writes such as `list drafts`, `download failed job logs`, `search messages`, `upload media`.
- Install name: a short binary name such as `ci-logs`, `slack-cli`, `sentry-logs`.

For a personal tool without a named repo, create it under `~/projects/clis/<tool-name>`.

Before scaffolding, check whether the proposed command already exists:

```bash
command -v <tool-name> || true
```

If it exists, choose a clearer install name or ask the user.

## Choose the Runtime

Inspect the machine first:

```bash
command -v cargo rustc node npm python3 uv || true
```

Then choose the least surprising toolchain:

- Default to **Rust** for a durable CLI an agent should run from any repo: one fast binary, strong argument parsing, good JSON handling, easy install into `~/.local/bin` or `~/.cargo/bin` (both on PATH here).
- Use **TypeScript/Node** when the official SDK, auth helper, browser automation library, or existing repo tooling is the reason the CLI can be better. Global installs land in `~/.npm-global/bin` (configured via `.npmrc`).
- Use **Python** when the source is data science, local file transforms, notebooks, SQLite/CSV/JSON analysis, or Python-heavy admin tooling that can still be installed as a durable command.

Pick a language that adds setup friction only when it materially improves the CLI. If the best toolchain is missing, install it via Homebrew (`brew install rust`, `brew install node`, `brew install uv`) with the user's approval, or choose the next-best installed option.

State the choice in one sentence before scaffolding, including the reason and the installed toolchain you found.

## Command Contract

Sketch the command surface in chat before coding. Include the binary name, discovery commands, resolve/ID-lookup commands, read commands, write commands, raw escape hatch, auth/config choice, and the install command.

Design the surface following the composable shapes in [agent-cli-patterns.md](references/agent-cli-patterns.md) — discover → resolve → read → context ordering, JSON/exit-code rules, pagination knobs, raw escape hatch.

Build toward this checklist:

- `tool-name --help` shows every major capability.
- `tool-name --json doctor` verifies config, auth, version, endpoint reachability, and missing setup.
- `tool-name init ...` stores local config when env-only auth is painful.
- Discovery commands find accounts, projects, workspaces, teams, queues, channels, repos, or other top-level containers.
- Resolve commands turn names, URLs, slugs, or permalinks into stable IDs so future commands don't repeat broad searches.
- Read commands fetch exact objects and list/search collections. Paginated lists support a bounded `--limit`, cursor, offset, or a clearly documented default.
- Write commands do one named action each: create, update, delete, upload, schedule, retry, comment, draft. They accept the narrowest stable resource ID, support `--dry-run`/`draft`/`preview` first when the service allows it, and keep writes out of broad commands such as `fix`, `debug`, or `auto`.
- `--json` returns stable machine-readable output.
- A raw escape hatch exists: `request`, `api`, or the nearest honest name.

Give the agent high-level verbs for the repeated jobs — a generic `request` command alone is not a contract.

Document the JSON policy in the CLI README: API pass-through versus CLI envelope, success shape, error shape, and one example per command family. Under `--json`, errors are machine-readable and contain no credentials.

## Auth and Config

Support the boring paths first, in this precedence order:

1. Environment variable using the service's standard name, such as `GITHUB_TOKEN` (the user keeps secrets in `~/.config/openai_key.sh`-style sourced files — suggest that pattern for new keys).
2. User config under `~/.<tool-name>/config.toml` or another simple documented path.
3. `--api-key` or a tool-specific token flag only for explicit one-off tests. Prefer env/config for normal use because flags leak into shell history and process listings.

Never print full tokens. `doctor --json` reports whether a token is available, the auth source category (`flag`, `env`, `config`, provider default, or missing), and what setup step is missing.

Fail fast: when required auth or config is missing for a command that needs it, exit nonzero with a one-line fix hint. Silent fallbacks and speculative defaults hide setup problems. The one deliberate exception is `doctor`, which reports missing auth instead of crashing.

For internal web apps sourced from DevTools curls, create sanitized endpoint notes before implementing: resource name, method/path, required headers, auth mechanism, CSRF behavior, request body, response ID fields, pagination, errors, and one redacted sample response. Keep copied cookies, bearer tokens, customer secrets, and full production payloads out of the repo.

Use screenshots to infer workflow, UI vocabulary, fields, and confirmation points — treat them as API evidence only when paired with a network request, export, docs page, or fixture.

## Build Workflow

1. Read the source just enough to inventory resources, auth, pagination, IDs, media/file flows, rate limits, and dangerous write actions. If the docs expose OpenAPI, download or inspect it before naming commands.
2. Sketch the command list in chat. Keep names short and shell-friendly.
3. Scaffold the CLI with a README, using the crates/packages and install targets from [language-defaults.md](references/language-defaults.md) for the chosen runtime.
4. Implement `doctor`, discovery, resolve, read commands, one narrow draft or dry-run write path if requested, and the raw escape hatch.
5. Install the CLI on PATH so `tool-name ...` works outside the source folder.
6. Smoke test from another repo or `/tmp`, not only with `cargo run` or package-manager wrappers. Run `command -v <tool-name>`, `<tool-name> --help`, and `<tool-name> --json doctor`.
7. Run format, typecheck/build, unit tests for request builders, pagination/request-body builders, no-auth `doctor`, help output, and at least one fixture, dry-run, or live read-only API call.

If a live write is needed for confidence, ask first and make it reversible or draft-only.

When the source is an existing script or shell history, split the working invocation into real phases: setup, discovery, download/export, transform/index, draft, upload, poll, live write. Preserve the flags, paths, and environment variables the user already relies on, then wrap the repeatable phases with stable IDs, bounded JSON, and file outputs.

For raw escape hatches, support read-only calls first. Run raw non-GET/HEAD requests against a live service only when the user asked for that specific write.

For media, artifact, or presigned upload flows, test each phase separately: create upload, transfer bytes, poll/read processing status, then attach or reference the resulting ID.

For fixture-backed prototypes, keep fixtures in a predictable project path and make the CLI locate them after installation. Smoke-test from `/tmp` to catch binaries that only work inside the source folder. If the CLI can run without network or auth, make that explicit in `doctor --json`: report fixture/offline mode, whether fixture data was found, and whether auth is required for that mode.

For log-oriented CLIs, keep deterministic snippet extraction separate from model interpretation. Prefer a command that emits filenames, line numbers or byte ranges, matched rules, and short excerpts.

## Companion Skill

After the CLI works, create or update a small skill for it following the conventions in the `skill-master` skill (frontmatter with "Use when:" triggers in both Russian and English, compact body, references for depth).

Write the companion skill in the order a future agent thread should use the CLI, not as a tour of every feature. Explain:

- How to verify the installed command exists.
- Which command to run first.
- How auth is configured.
- Which discovery command finds the common ID.
- The safe read path.
- The intended draft/write path.
- The raw escape hatch.
- What requires explicit user approval.
- Three copy-pasteable command examples.

Keep API reference details in the CLI docs or a skill reference file. Keep the skill focused on ordering, safety, and examples future threads should actually run.

New companion skills go to `~/projects/dotfiles/claude-code/skills/<tool-name>/` — this directory is the single source of truth, symlinked into Amp and Qwen Code, so the skill becomes available across all the user's AI coding tools automatically.

## Done when

- The command is on PATH and runs from `/tmp`, not only from the source folder.
- `--json` output is stable and `<tool-name> --json doctor` passes.
- Auth precedence works: env → config → flags.
- A companion skill exists in `~/projects/dotfiles/claude-code/skills/`.
