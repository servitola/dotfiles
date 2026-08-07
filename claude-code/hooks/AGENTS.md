# claude-code/hooks — bodies of the Claude Code hook commands

`../settings.json` wires the hooks; this directory holds their bodies. JSON has no
comments and no line breaks inside a string, so any hook longer than a launcher line
lives here as its own script and the `"command"` is just:

```json
"command": "$HOME/.claude/hooks/<name>.sh"
"command": "python3 $HOME/.claude/hooks/<name>.py"
```

Same convention as `fork/scripts/` for the Fork GUI. Change hook
**logic** here, never by inlining it back into `settings.json`.

Claude Code pipes the hook payload (JSON) on stdin — read it with `jq -r '.some.key'`
when the hook needs the tool input. Every hook must exit 0 on any path it does not
care about; a non-zero exit is a blocked tool call.

## Scripts

| file | hook event |
|---|---|
| `guard-bash.py` | PreToolUse(Bash) — deny rules |
| `compress-bash-output.py` | PostToolUse(Bash) — shrink output |
| `post-edit-typecheck.sh` | PostToolUse(Edit\|Write\|MultiEdit) — `go vet` for `.go`, `rtk tsc --noEmit` for `.ts` |
| `rag-context-inject.py` | UserPromptSubmit — dotfiles RAG context |
| `post-compact-restore.sh` | SessionStart(compact) |

`skill-usage-log.sh` lives in `../skill-usage/`, next to its stats script.

## Third-party hook injection

`aoe` (Agent of Empires) used to inject nine hook entries here — status writers marked
with a trailing `# aoe-hooks` comment. It was uninstalled 2026-07 and its entries
removed. Lesson for the next tool that does this: such a tool re-injects its **own**
long form on launch and does not recognise a collapsed launcher, so the two coexisted
as duplicates. If unexplained one-liners appear in `settings.json`, find the tool that
owns them before editing.
