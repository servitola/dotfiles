# fork/scripts — bodies of the larger Fork custom commands

Fork reads `../custom-commands.json` (via two symlinks from
`~/Library/Application Support/com.DanPristupov.Fork/custom-commands.json`).
Small one-liner commands stay inline in that JSON. Anything multi-line lives
here as its own `*.sh`, and the JSON entry is just a launcher:

```json
"script": "\"$HOME/projects/dotfiles/fork/scripts/<name>.sh\" \"$sha\" \"${repo:path}\""
```

Fork substitutes `${repo:path}` (and `$sha` for revision targets) before
running; each arrives as a positional arg. Convention inside each script:

- `sha="$1"` when the command needs the selected commit (`target: revision`)
- `repo="$2"` (or `"$1"` when there is no `sha`) when it needs the repo path
- launcher passes only the args the script actually reads, in that order

`lib.sh` holds the shared helpers — source it, don't redefine:

- `alert TITLE MESSAGE` — critical macOS alert
- `notify MESSAGE` — notification titled "Fork"
- `waitlock` — block until the repo's `index.lock` clears (Fork holds it briefly)

Editing rules:
- Change command **logic** in the `.sh` file, not in Fork's GUI (the GUI would
  only see the launcher line).
- Adding a **new** command is still fine via the GUI; if it grows large, move
  its body here and swap in a launcher.
- Keep scripts executable (`chmod +x`); `lib.sh` is sourced, not run.
