# cron — scheduled jobs (Telegram reminders, feeds, work snapshots, maintenance) installed into the user's crontab from versioned files

- `cron_jobs/*.cron` are crontab fragments — one concern per file. New/personal entries always go into `*.private.cron` files, which are gitignored (`.gitignore`: `cron/cron_jobs/*.private.cron`); committed `.cron` files hold shareable jobs only.
- `init-cron-jobs.sh` is the installer: it concatenates `environment.cron` (SHELL/PATH) first, then every `cron_jobs/*.cron` alphabetically, and pipes the result to `crontab -`. It fully replaces the active crontab — editing a fragment does nothing until this script is re-run.
- Add a job by creating/editing a `.cron` fragment (schedule + command line; put real commands in `scripts/` and append `>> logfile 2>&1`), then running `./init-cron-jobs.sh`. Keep overlap-prone jobs idempotent via a lockfile or run-once wrapper.
- `scripts/` holds the actual job logic (shell/python) the fragments invoke; `logs/` collects per-job output (some jobs log to `~/Library/Logs/` or `/tmp` instead — see each fragment's header).
- Telegram-posting jobs (work-snapshot, greek-daily, reminders, feeds) send via `scripts/tg-send.sh` / `tg-send-thread.sh` to specific chat/topic threads; credentials and config live under `~/.config/`.
- `rag-improve.cron` lives here but drives the sibling `rag/` system: it runs `rag/scripts/rag-improve.py` hourly to expand/eval the RAG corpus, writing back into `rag/` — the cron schedule belongs to cron, the behavior belongs to rag.
- The cron-job and reminder workflows are authored via the `cron-job` skill, which knows this layout and re-runs `init-cron-jobs.sh` after edits.
