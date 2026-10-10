# cron — the mechanism that turns a directory of `.cron` fragments into the user's crontab, plus the calendar and weekly report that watch it

The jobs themselves are personal and live in another repository; this directory
holds only what is true for anyone. Point three constants at your own
repository and everything here works:

| Constant | Meaning |
|---|---|
| `DIR_CRON` | the jobs repository; `$DIR_CRON/logs/` collects per-job output, `$DIR_CRON/cron-calendar.html` is the rendered calendar |
| `DIR_CRON_JOBS` | `**/*.cron` fragments, any depth of theme subfolders |
| `DIR_CRON_SCRIPTS` | what the fragments call, written as `$DIR_CRON_SCRIPTS/foo.sh` |
| `TG_CHAT_NOTIFY` + `TG_THREAD_CRON` | where `weekly-report.sh` posts |

On this machine they point at `~/projects/cron` (private, Gitea), whose
`AGENTS.md` describes the fragments.

- `install.sh` (command `cron-install`) concatenates `environment.cron`
  (`SHELL=/bin/zsh`, `PATH`) and every fragment under `$DIR_CRON_JOBS` sorted by
  file name — not path, so moving a fragment between theme folders never changes
  the merge order — and pipes the result to `crontab -`, replacing the whole
  crontab. Editing a fragment changes nothing until it runs; `--print` shows the
  result without installing. `crontab` needs Full Disk Access, which an agent
  shell lacks: the owner runs `cron-install`, an agent's call hangs.
- A fragment is a crontab excerpt: a header comment, then `<schedule> <command>
  >> $DIR_CRON/logs/<name>.log 2>&1`. Because `SHELL` is zsh and zsh sources
  `~/.zshenv`, every constant is exported into the job — fragments write
  `$DIR_CRON_SCRIPTS/…` and `$TG_CHAT_MAIN`, never a literal path or id.
- `cron-calendar.py` (command `cron-cal`) renders a static Apple-glass Gruvbox
  dashboard of every job; `cron-report.py` (`cron-cal --report`) prints the
  weekly health text — problems first: jobs whose log has been silent for over
  20× their interval, jobs with no log at all, duplicated lines. Both are stdlib
  only and read the same fragment set the installer does (`collect_fragments`
  walks subfolders; `tests/test_cron_calendar.py` pins it). `weekly-report.sh`
  posts the text with `tg` every Monday; the fragment that schedules it lives
  with the other jobs. Tests: `uv run --with pytest python -m pytest -q cron/tests`.
- A job that needs the login keychain or a mounted volume cannot be a cron job:
  crontab runs from a LaunchDaemon without a user security session, and TCC
  attributes a script to its interpreter. Such a job is a LaunchAgent whose
  `ProgramArguments` names a compiled binary — see `~/projects/forks` and
  `launchagents/`.
- `install/15-ci-guarded.sh` runs `install.sh` as part of `make`;
  `install/check.sh` asserts the live crontab equals `install.sh --print`.
