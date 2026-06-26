---
name: insight-miner
description: |
  Mines Claude Code transcripts for recurring friction and proposes concrete tooling
  improvements (aliases, CLAUDE.md rules, settings allowlist, serho-platform fixes).
  Human-gated: nothing is applied without review. The "controlled dream".

  Use when: "запусти insight-miner", "что улучшить в тулинге", "разбери трение за неделю",
  "insight-miner review", "mine my transcripts", "what should I improve"
---

# insight-miner

Compounding learning loop over `~/.claude` transcripts. Cheap deterministic capture
(cron, 0 LLM) → weekly Telegram nudge → **interactive review where the LLM judgment lives**
(no headless `claude -p`). Output: reviewed diffs committed to dotfiles + an append-only ledger.

## Architecture

| Layer | When | Cost | What |
|---|---|---|---|
| `collect.py scan` | nightly cron | 0 LLM | mtime>watermark → `events.jsonl` |
| `collect.py tg` | weekly cron | 0 LLM | compact digest → Telegram topic 🧠 Insights |
| **`/insight-miner review`** | on demand (you) | LLM (this session) | judge → dedup → propose diffs → apply → commit → ledger |
| `collect.py report` | on demand | 0 LLM | full human digest |

State: `~/.local/state/insight-miner/` (events.jsonl, watermark, report.json).
Ledger (git, RAG-indexed): `claude-code-memory/insights.md`.

## Scope = attribution (NOT privacy)

- `own` / `work=Spotware` → **you** → personal tooling, aliases, CLAUDE.md rules.
- `serho` (gokar, serho-users, Renata-bot, Marina, mama) → **friends+bot, not you** →
  improve the platform broadly. Never write friend-driven corrections as your personal rules.

## Signals → artifact

| Signal | Target |
|---|---|
| repeated non-plumbing command | `zsh/aliases.sh` / `~/.ssh/config` / helper script |
| permission prompt | `/fewer-permission-prompts` (scoped to that project's settings) |
| `Edit: string not found` | read-before-edit rule in `CLAUDE.md` |
| `Refusing to write through symlink` | symlink-edit rule in `CLAUDE.md` |
| your correction (from history.jsonl) | `CLAUDE.md` rule |
| serho infra (`uv run --with` spam, `sshpass`) | platform fix (pin venv, SSH keys) |

## Review workflow (what I do when invoked)

1. `python3 scripts/collect.py report --days 7` — read current candidates.
2. Load `claude-code-memory/insights.md`; skip any `fp` already logged (dedup).
3. For each fresh candidate cluster: form a concrete proposal + the exact diff.
4. Present grouped by scope. For each: **approve** → apply edit + atomic commit (dotfiles
   `[component] …` style); **reject** → log `rejected`; **snooze:Nw** → log snoozed.
5. Append every decision to the ledger with `fp`, evidence count, status (+ commit SHA if applied).
6. Never auto-apply. One commit per logical change. Never `git add -A`.

## Ledger entry format

```
## YYYY-MM-DD · <kind> · <status>
fp: <scope>|<kind>|<sig>
evidence: <n>× last <window>
proposal: <one line>
diff: <file> (+/-)
status: proposed | applied <date> <sha> | rejected | snoozed:Nw
```

See `references/signal-catalog.md` for detectors and examples.
