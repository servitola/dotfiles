# Signal catalog

Detectors are deterministic (jq/python over JSONL). Each maps a transcript signal to a
tooling artifact. Scope tags attribution only (own/work=you, serho=friends+bot→platform).

| # | Signal | Detector | Artifact |
|---|---|---|---|
| 1 | repeated manual command | `tool_use name=Bash → .input.command`, normalize (drop leading env-assign, sanitize paths/ids), first 3 tokens, count ≥3; exclude PLUMBING verbs | `zsh/aliases.sh`, `~/.ssh/config`, helper script |
| 2 | command/file not found | `tool_result.is_error` + `not found` / exit 127 | alias + PATH rule in `CLAUDE.md` |
| 3 | failed Edit | `is_error` + `String to replace not found` | "Read before Edit" rule |
| 4 | write through symlink | `Refusing to write through symlink` | symlink-edit rule (common in dotfiles) |
| 5 | your correction | `history.jsonl.display` matches CORR regex, short (<220), not a paste/skill-load | `CLAUDE.md` rule |
| 6 | permission prompt | `Permission to use <tool> with command <verb>` | `/fewer-permission-prompts` on that project's settings |
| 7 | repeated task class | cluster `history.jsonl.display` by similarity | new skill/command stub |
| 8 | serho infra friction | serho-scope: `uv run --with` spam, `sshpass -p …`, repeated remote ops | platform fix: pin venv/`uv sync`, SSH keys |

## Noise filters (learned from MVP)
- PLUMBING verbs (cd/ls/echo/grep/find/cp/…) are agent-internal → excluded from command view.
- Pure env-assignments / heredoc captures (`L="…"`) → dropped (return None).
- Corrections come from `history.jsonl`, not transcripts — transcripts leak skill-load
  attachments ("Base directory for this skill…") and continuation summaries.

## Dedup
`fp = scope|kind|sig`. Before proposing, skip any fp already in the ledger
(any status). `rejected` = never resurface; `snoozed:Nw` = resurface after N weeks.
