# Custom commands (`zsh/bin/`)

Executables on PATH (`zsh/bin/` is added in `zsh/exports-path.sh`). Unlike
interactive aliases/functions, these work in **non-interactive shells** — i.e.
the Bash tool used by Claude Code / Codex / Qwen. **Prefer these over
re-deriving an inline heredoc**: a named command is fewer tokens, doesn't fail
the way an ad-hoc one-liner does, and its output can be filtered by RTK.

Run any with `--help`/no args for usage. When a recurring task turns into a
20-line inline python/bash heredoc, add it here instead.

| Command | What it does |
|---|---|
| `const [KEY]` | Read the constants of this machine — `const app.browser`, `const DIR_WORK`, `const list DIR_`, bare `const` lists all. `const check` validates the file against `constants/schema.toml` and its consumers; `const literals` lists hardcoded private values. Same values are exported into every shell. Source: `constants/AGENTS.md`. |
| `tg [-c chat] [-t thread] [text]` | Send to Telegram as the bot: `tg "text"` (main chat), `tg -c notify -t 1486 "text"`, `cmd \| tg -t 1486` (stdin), `--file PATH` / `--audio PATH` (text becomes the caption), `--html`. The chat is a name with a `TG_CHAT_<NAME>` constant (`main`, `notify`) or a numeric id; a rejected request is a non-zero exit. The one sender for every script and repository — `$DIR_CRON_SCRIPTS/tg-send*.sh` are wrappers kept for old callers. Test: `zsh zsh/tests/tg.test.zsh` (stub server, nothing is sent). |
| `rag` | Query a RAG collection (Qdrant + LiteLLM); wrapper over `$DIR_RAG/rag.sh` from the `~/projects/rag` repository. `rag context --collection dotfiles -k 8 "<q>"`. |
| `litellm-config-diff [ref]` | Diff `litellm/config.yaml` model_list vs HEAD (or `ref`) by model_name count. |
| `broken-links` | Report dangling symlinks in `$HOME` + bin dirs (`PRUNE_BROKEN_LINKS=true` to rm). Foreign FS pruned. |
| `perfcheck` | One-shot macOS performance diagnostic for this machine. |
| `new-topic` | Create/top-up a "topic" folder with AGENTS.md + CLAUDE.md symlink. |
| `agents-link` | Ensure a dir has both AGENTS.md and CLAUDE.md (symlink to AGENTS.md). |
| `skill-attach <name> [dir]` | Attach a detached skill (`$DIR_SKILLS/detached_skills/<name>`) to a folder (project scope). |
| `skill-stats` | Skill usage stats. |
| `cc-usage` | Claude Code token-spend analytics from transcripts. Summary shows cost-by-token-class (cache-read/write/output/input — where the money goes); `--by day\|project\|model\|session` (⚡ flags cost spikes), `--savings` for spend vs. RTK-saved, `--digest` (weekly cron text), `--since Nd`, `--json`. |
| `cron-cal` | Regenerate + open the static cron calendar (Apple-glass Gruvbox HTML written to `$DIR_CRON/cron-calendar.html`). Reads fragments from `$DIR_CRON_JOBS/`; splits background pollers from scheduled events, flags dead/silent/duplicate jobs. `--quiet` regenerate only, `--report` print the weekly Telegram text. |
| `cron-install` | Rebuild the crontab from `$DIR_CRON_JOBS/**/*.cron` (plus `cron/environment.cron`) and install it with `crontab -`; `--print` shows the merge without installing. Needs Full Disk Access, so the owner runs it, not an agent. Mechanism: `cron/AGENTS.md`. |
| `git-rl [args]` | `git reflog` with the entry's ISO timestamp, its age and its `HEAD@{N}` index side by side — the builtin `--date=` replaces the index instead of adding a column, and reflog ignores `log.date`. Named so git resolves it as `git rl`; takes any `git log -g` argument (`git rl -n 20`, `git rl master`). |
| `mcp-attach <name> [dir]` | Attach a detached MCP server to a folder. |
| `serho-restart [--quiet]` | Restart the serho bot LaunchAgent (`com.servitola.serho`). Picks `kickstart -k` vs `bootstrap` by actual launchd state, heals the missing-log-dir trap, then waits for `Start polling` in `bot.log` — exits non-zero if the bot never comes up. Use this instead of raw launchctl: a bare `bootout` leaves the label unregistered and every later `kickstart` a silent no-op. |
| `sync-friend-skills` | Re-apply each bot user's skill allowlist (serho bot). |
| `ytmcp` | Toggle the workname YouTrack MCP server on demand. |
| `yt-rutube <url>` | Download from Rutube with the `ytv` video config, retrying through `PROXY_BLANC_MOSCOW` (socks5h) when the geo-block hits. Interactive aliases: `ytrutube` / `ytr`. |

## Why this exists (token economics)

`rtk discover` and `rtk learn` showed the AI repeatedly writing the same
*categories* of large inline heredocs (config diffs, symlink audits, batch
commits). Each is expensive on input **and** output, error-prone (they fail →
re-run = double tokens), and opaque to RTK (it can only compact a named
command's output, not an inline script). Promoting recurring heredocs to
scripts here is the single biggest token lever for this repo — bigger than
`rtk learn`, which finds **0 recurring corrections** because every heredoc is a
unique one-off.
