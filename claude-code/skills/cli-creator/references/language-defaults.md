# Language Defaults

Use this reference after choosing the runtime. Each section lists the boring, established stack and the install path for this machine (macOS, Homebrew toolchains, PATH already includes `~/.local/bin`, `~/.cargo/bin`, and `~/.npm-global/bin`).

## Rust

Use established crates instead of custom parsers:

- `clap` (derive) for commands and help
- `reqwest` for HTTP
- `serde` / `serde_json` for payloads
- `toml` for small config files
- `anyhow` for CLI-shaped error context

Install:

- Add a `Makefile` target such as `make install-local` that runs `cargo build --release` and copies the binary into `~/.local/bin`.
- `cargo install --path .` into `~/.cargo/bin` is an equivalent alternative — both directories are on PATH.
- Toolchain missing? `brew install rust` (or rustup if the user prefers managed toolchains).

## TypeScript/Node

Keep the CLI installable as a normal command:

- `commander` or `cac` for commands and help
- native `fetch`, the official SDK, or the user's existing HTTP helper for API calls
- `zod` only where external payload validation prevents real breakage
- `package.json` `bin` entry for the installed command
- `tsup`, `tsx`, or `tsc` following the repo's existing convention

Install:

- `npm link` or `npm install -g .` — globals land in `~/.npm-global/bin` (configured via `.npmrc`), already on PATH.
- Alternatively a `Makefile` target that installs a small wrapper into `~/.local/bin`.
- If the tool should survive machine rebuilds as a published package, add it to `~/projects/dotfiles/npm/global-packages.txt`.

## Python

Prefer boring standard-library pieces unless the workflow needs more:

- `argparse` for commands and help, or `typer` when subcommands would otherwise get messy
- `urllib.request` / `urllib.parse`, `requests`, or `httpx` for HTTP — match what is already installed or used nearby
- `json`, `csv`, `sqlite3`, `pathlib`, and `subprocess` for local files, exports, databases, and existing scripts
- `pyproject.toml` console script or a small executable wrapper for the installed command
- `uv` or a virtualenv only when dependencies are actually needed

Install:

- With dependencies: `uv tool install .` (or `pipx`) — isolated env, command on PATH.
- Stdlib-only: a small executable wrapper in `~/.local/bin` pointing at system `python3`.
- Add a `Makefile` target such as `make install-local` and document whether it depends on `uv`, a virtualenv, or only system Python.

## Shared conventions

- Fail fast: required config, auth, or paths missing → exit nonzero with a one-line fix hint. Silent fallbacks hide setup problems (this matches the dotfiles fail-fast philosophy).
- README documents: install command, auth setup, JSON policy (envelope vs pass-through, success/error shapes), and one example per command family.
- Smoke test the installed command from `/tmp`, never only via `cargo run` / `npx` / `python -m` wrappers.
