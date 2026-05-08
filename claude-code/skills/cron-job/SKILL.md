---
name: cron-job
description: |
  Add, edit, or remove scheduled tasks in the dotfiles cron setup at
  ~/projects/dotfiles/cron/cron_jobs/. Picks the right file, validates the
  schedule expression, wires logging/locking, and reinstalls crontab via
  init-cron-jobs.sh. New entries always go into private (gitignored) files.

  Use when: "добавь крон", "новая задача по расписанию", "запланируй задачу",
  "поставь в крон", "schedule a task", "add a cron job", "add to crontab",
  "запиши в крон", "убери из крона", "remove cron job", "edit cron schedule".
---

# Cron Job

Manages scheduled tasks in `~/projects/dotfiles/cron/cron_jobs/`. Source of truth is files in that directory; the live crontab is derived from them.

## How the dotfiles cron works

- `cron/environment.cron` — `SHELL`, `PATH` for all jobs. Loaded first.
- `cron/cron_jobs/*.cron` — one file per topic/project. Concatenated alphabetically after `environment.cron`.
- `cron/init-cron-jobs.sh` — pipes the merged result into `crontab -`, replacing the entire crontab. No partial updates, so a change is only live after the script runs.
- macOS `cron` runs from `/usr/sbin/cron` and needs Full Disk Access granted in System Settings → Privacy & Security if the job touches `~/Documents`, `~/Desktop`, etc. Mention this to the user only when relevant.

## Always private by default

New cron entries always go into `<topic>.private.cron` files. The `*.private.cron` pattern is gitignored, so nothing leaks to git by accident. The user reviews and promotes specific entries to public files later if needed — that's not part of this skill.

Existing public `<topic>.cron` files may already be in `cron_jobs/` (e.g. `audiorss.cron`, `mma.cron`). When appending to an existing topic, keep using whichever file already exists — don't migrate it. New topics always start as `.private.cron`.

## Workflow

### 1. Gather what's needed

Confirm with the user (skip questions whose answers are obvious from context):

- **What runs** — full command or absolute path to a script.
- **When** — schedule in plain words ("каждые 30 минут", "по пятницам в 10 утра"). Convert to cron expression yourself.
- **Logging** — does the script already log somewhere, or should the cron line redirect output? Most jobs want `>> /path/to/log 2>&1`.
- **Concurrency** — can two runs overlap? If not and the script doesn't lock itself, wrap with `flock` or note it for the user.

### 2. Pick the file

- Existing topic with a file in `cron_jobs/` → append to it. Group related lines under the same file.
- New topic → create `<topic>.private.cron`. `<topic>` matches the project/service name in kebab-case (match neighbour style if related: `rag-improve.cron`, `audiorss.cron`). Group multiple related entries in one file with a header comment — see `cron/cron_jobs/mma.cron`.

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

## Removing or changing entries

- Edit the file, run `init-cron-jobs.sh`, verify with `crontab -l`. Same flow.
- Removing the last entry from a file → delete the file too, don't leave an empty `.cron` stub.
