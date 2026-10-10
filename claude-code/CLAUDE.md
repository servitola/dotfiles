You are full assistant to servitola user on MacOS who is Advanced Mobile Fintech CTO

# Environment Configuration

- **Constants of this machine** (paths, chosen browser/terminal/editor, Telegram
  chat ids, hosts): `const <key>` — e.g. `const app.browser`, `const DIR_WORK`,
  `const list TG_`. Bare `const` lists everything. They are also exported into
  every shell (`$APP_BROWSER`, `$DIR_WORK`). Never hardcode such a value in a
  new script or ask the user for it — read it, and add it there when it is
  missing (`~/projects/dotfiles/constants/AGENTS.md`).
- Work: ~/projects/workname
- Dotfiles: ~/projects/dotfiles
- List of apps ~/projects/dotfiles/homebrew/brewfile
- secrets and api keys: ~/.config/openai_key.sh

# Rules

- When debugging, always establish the root cause with evidence before proposing fixes. Do not guess or apply speculative patches.
- When editing shell scripts, be careful with quoting, associative arrays, and sed regex syntax.
- Before writing code, walk the ladder: (1) does this need to exist at all, (2) is it already in the codebase, (3) does the stdlib or the native platform already do it (`<input type="date">` instead of a date-picker component), (4) does it fit in one line. A new dependency or a "for later" abstraction needs an explicit justification. This does NOT apply to validation, error handling, security, or accessibility — never minimize those.
- I hate comments. A comment earns its place only by explaining something the reader cannot get from the code: **why** this and not the obvious alternative, a constraint learned the hard way, a magic number's provenance, a non-local ordering requirement. Never write: a banner or `# ====` frame, a label restating the next line (`# Go` above `path+=($GOPATH/bin)`), a function's own name as prose, or a header manual duplicating `--help` / an `AGENTS.md`. Prefer a clearer name or a smaller function over a comment that explains a confusing one.
- Parallelize work across agents when it helps — but with a budget gate. You may launch up to 5 agents (and lightweight, clearly-bounded tool fan-outs) without asking. Before launching MORE than 5 agents — including any workflow/harness that fans out many subagents (e.g. the deep-research skill, which can spawn 100+) — STOP and ask for explicit approval first, stating roughly how many agents and how many tokens it will cost. No heavyweight multi-agent run without a go-ahead.
- Codex will review your output once you are done
- When creating a git worktree branch from a remote ref (e.g. `origin/Development`, `origin/main`, `origin/master`), ALWAYS pass `--no-track` so the new branch does not set the protected upstream as its push target. Example: `git worktree add <path> -b <new-branch> --no-track origin/Development`. Never let a feature/fix branch track a primary upstream — a stray `git push` could land work on the protected branch by accident.
- NEVER `git push` and NEVER create merge requests / pull requests unless the user explicitly asks for it in the current conversation. Local commits are fine; everything that leaves the machine (push, MR/PR, ticket updates that publish links) waits for an explicit go-ahead.
- NEVER turn the VPN on/off yourself until asked directly (e.g. `scutil --nc start/stop "awg-client"`, AmneziaWG, any VPN service). If something seems to need the VPN, tell the user and let them connect it

# Shared AI Coding Tools

This `claude-code/` directory is the single source of truth for commands, agents, and skills.
When adding or editing commands/agents/skills — do it here. All tools pick up changes automatically.
