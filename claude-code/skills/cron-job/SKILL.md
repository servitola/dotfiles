---
name: cron-job
description: |
  Add, edit, or remove scheduled tasks AND reminders (scheduled Telegram
  messages) in the dotfiles cron: picks the right file, validates the
  schedule, wires logging/locking, reinstalls crontab via init-cron-jobs.sh.
  New private entries go into the dotfiles_private overlay
  (~/projects/dotfiles_private/cron/cron_jobs/); shareable jobs into public
  ~/projects/dotfiles/cron/cron_jobs/.

  Use when: "добавь крон", "запланируй задачу", "поставь в крон", "запиши
  в крон", "убери из крона", "schedule a task", "add a cron job", "add to
  crontab", "remove cron job", "напомни мне", "поставь напоминание",
  "напоминай каждый", "remind me", "set a reminder", "ping me at".
---

# Cron Job

Manages scheduled tasks split across two dirs: public `~/projects/dotfiles/cron/cron_jobs/` (shareable) and the private overlay `~/projects/dotfiles_private/cron/cron_jobs/` (personal). Source of truth is the fragment files; the live crontab is derived from both.

## How the dotfiles cron works

- `cron/environment.cron` — `SHELL`, `PATH` for all jobs. Loaded first.
- `cron/cron_jobs/*.cron` — shareable jobs, committed to the public dotfiles repo. One file per topic/project.
- `~/projects/dotfiles_private/cron/cron_jobs/*.private.cron` — private jobs, committed to the `dotfiles_private` overlay repo. This is where all personal entries live now (no symlinks, no gitignore trick).
- `cron/init-cron-jobs.sh` — reads `.cron` fragments from BOTH dirs, merges them sorted by filename after `environment.cron`, and pipes the result into `crontab -`, replacing the entire crontab. No partial updates, so a change is only live after the script runs.
- macOS `cron` runs from `/usr/sbin/cron` and needs Full Disk Access granted in System Settings → Privacy & Security if the job touches `~/Documents`, `~/Desktop`, etc. Mention this to the user only when relevant.

## Always private by default

New cron entries always go into `<topic>.private.cron` files under the private overlay `~/projects/dotfiles_private/cron/cron_jobs/` — never in the public `~/projects/dotfiles/cron/cron_jobs/`, which is committed to the public repo. Committing there would leak the entry. After creating/editing a private fragment, commit it in the `dotfiles_private` repo (do not push unless asked).

Existing public `<topic>.cron` files may already be in the public `cron_jobs/` (e.g. `audiorss.cron`, `rag-improve.cron`). When appending to an existing topic, keep using whichever file already exists (public or private) — don't migrate it. New topics always start as `.private.cron` in the overlay.

## Workflow

### 1. Gather what's needed

Confirm with the user (skip questions whose answers are obvious from context):

- **What runs** — full command or absolute path to a script.
- **When** — schedule in plain words ("каждые 30 минут", "по пятницам в 10 утра"). Convert to cron expression yourself.
- **Logging** — does the script already log somewhere, or should the cron line redirect output? Most jobs want `>> /path/to/log 2>&1`.
- **Concurrency** — can two runs overlap? If not and the script doesn't lock itself, wrap with `flock` or note it for the user.

### 2. Pick the file

- Existing topic with a file in either `cron_jobs/` dir → append to it. Group related lines under the same file.
- New topic → create `<topic>.private.cron` in `~/projects/dotfiles_private/cron/cron_jobs/`. `<topic>` matches the project/service name in kebab-case (match neighbour style if related: `rag-improve.cron`, `audiorss.cron`). Group multiple related entries in one file with a header comment — see `~/projects/dotfiles_private/cron/cron_jobs/mma.private.cron`.

### 3. Write the entry

Format:

```
# Short description: what + why
<schedule> <command> [redirections]
```

Rules for the entry:
- Use absolute paths for binaries and scripts. `cron` runs with a minimal `PATH`; `environment.cron` adds `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` but anything outside that needs full path or a wrapper.
- Redirect output unless the script already does it: `>> /path/to/log 2>&1` (inline pattern in `cron/cron_jobs/rag-improve.cron`). Without redirection, cron mails output to a local mailbox the user never reads.
- For long-running or overlap-sensitive jobs, prefer a wrapper script that does its own `flock` rather than inlining `flock` in the cron line — `cron/cron_jobs/audiorss.cron` calls `run-once.sh` which handles the lock internally.
- Comment above each entry explaining purpose in one line — future-you will thank you.

Cron schedule cheatsheet (5 fields: minute hour day-of-month month day-of-week):

```
*/30 * * * *    every 30 minutes
0 3 * * *       daily at 03:00
0 4 * * 2       Tuesday 04:00          (0 or 7 = Sunday)
0 10 * * 5      Friday 10:00
29 7 * * 6      Saturday 07:29
0 9 1 * *       1st of month, 09:00
0 */2 * * *     every 2 hours, on the hour
```

Validate the expression mentally before writing — `crontab -` accepts garbage and silently never fires.

### 4. Install

After editing or creating files, run:

```bash
~/projects/dotfiles/cron/init-cron-jobs.sh
```

Then verify the entry is live:

```bash
crontab -l | grep -F '<distinctive substring of the new line>'
```

If `crontab -l` doesn't show it, `init-cron-jobs.sh` failed silently or matched nothing — re-read the file you edited and re-run.

### 5. Tell the user what changed

One short summary: which file was touched, the schedule in plain words, and the log path if any. The file is private and won't sync to other machines via git — mention that once.

## Reminders (delivered via Telegram)

A "reminder" is just a cron entry that posts a Telegram message at the scheduled
time — reminders here go to **Telegram**, not macOS notifications. Two helpers do
the sending (each sources the bot token from
`~/projects/services/telegram-bot/scripts/.env` and POSTs to the local bot API):

- `~/projects/dotfiles/cron/scripts/tg-send.sh <chat_id> "<text>"` — plain chat
- `~/projects/dotfiles/cron/scripts/tg-send-thread.sh <chat_id> <thread_id> "<text>"` — forum-topic thread

**Always confirm the destination** (chat_id / thread_id) with the user, or reuse
an existing reminders file's target. Existing example to copy the shape from:
any `~/projects/dotfiles_private/cron/cron_jobs/*-reminders.private.cron`
(documents its chat + thread + a timezone-offset note in the header).

Recurring reminder — inline the helper in the cron line:

```
# Reminder: weekly review, Fri 17:00
0 17 * * 5 /Users/servitola/projects/dotfiles/cron/scripts/tg-send-thread.sh <chat_id> <thread_id> "🗒️ Еженедельный обзор" >> /Users/servitola/projects/dotfiles/cron/logs/reminders.log 2>&1
```

For reminders with logic (rotation, conditions, dynamic text), write a script in
`cron/scripts/` and call it from cron — see `greek-daily-reminder.sh` for the
pattern (`SEND="$HOME/.../tg-send-thread.sh"; exec "$SEND" "$CHAT_ID" "$THREAD_ID" "$MSG"`).

**One-shot reminders** ("напомни завтра в 15:00"): cron is recurring by nature,
so use a specific date — `M H D Mo *` (e.g. `0 15 9 6 *` = Jun 9, 15:00). It
fires once; then **delete the entry and re-run `init-cron-jobs.sh`** — it will
NOT clean itself up. Tell the user this.

**Timezone:** the host runs in EEST (UTC+3). When the user gives a wall-clock
time for someone in another zone, convert to host TZ (the private reminders
files document per-person offset examples, e.g. UTC+7 → −4h).

## Removing or changing entries

- Edit the file, run `init-cron-jobs.sh`, verify with `crontab -l`. Same flow.
- Removing the last entry from a file → delete the file too, don't leave an empty `.cron` stub.
