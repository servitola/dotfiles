---
name: python-debugpy
description: |
  Debug Python from the terminal with pdb (local/post-mortem) and debugpy (remote DAP, attach to running processes).

  Use when: "отладь python", "поставь брейкпоинт в python", "отладь падающий тест", "debug python", "set a python breakpoint", "attach a debugger to a running python process"
---

# Python Debugger (pdb + debugpy)

## Overview

Three tools, picked by situation:

| Tool | When |
|---|---|
| **`breakpoint()` + pdb** | Local, interactive, simplest. Add `breakpoint()` in the source, run normally, get a REPL at that line. |
| **`python -m pdb`** | Launch an existing script under pdb with no source edits. Useful for quick poking. |
| **`debugpy`** | Remote / headless / "attach to already-running process." Talks DAP, scriptable from terminal, works for long-lived processes (gateway, daemon, PTY children). |

**Start with `breakpoint()`.** It's the cheapest thing that works.

## When to Use

- A test fails and the traceback doesn't reveal why a value is wrong
- You need to step through a function and watch a collection mutate
- A long-running process (a server, daemon, gateway) misbehaves and you can't restart it
- Post-mortem: an exception fired in prod-ish code and you want to inspect locals at the crash site
- A subprocess / child (a worker process, PTY bridge worker) is the actual bug site

**Don't use for:** things `print()` / `logging.debug` solve in under a minute, or things `pytest -vv --tb=long --showlocals` already reveals.

## Happy Path: Local breakpoint

Easiest — works for any one-shot CLI entry point or script you control. Edit the file:

```python
def compute(x, y):
    result = some_helper(x)
    breakpoint()           # <-- drops into pdb here
    return result + y
```

Run the code normally. You land at the `breakpoint()` line with full access to locals; control returns to your terminal at the pause point. Drive the pdb prompt with commands from [inspect-state.md](references/inspect-state.md).

Two things that bite:

- **`breakpoint()` in CI / non-TTY contexts hangs the process.** Safe locally; never commit it. Use `git diff` or a pre-commit grep as a safety net:
  ```bash
  rg -n 'breakpoint\(\)' --type py
  ```
- **`PYTHONBREAKPOINT=0`** disables all `breakpoint()` calls. Check the env if your breakpoint isn't hitting:
  ```bash
  echo $PYTHONBREAKPOINT
  ```

## What do you need?

Load the smallest set of references that fits the task — usually exactly one branch.

```
Launch something under a debugger?
├─ Script / module, no source edits     → launch-under-debugger.md
├─ Failing pytest test (--pdb, xdist)   → launch-under-debugger.md
└─ Post-mortem on an exception          → launch-under-debugger.md

Attach to an already-running process?
├─ Server / gateway / daemon            → attach-to-running-process.md
├─ Subprocess spawned by another app    → attach-to-running-process.md
└─ Attach by PID (debugpy --pid)        → attach-to-running-process.md

Inside a (Pdb) prompt already?
└─ Stepping, breakpoints, state         → inspect-state.md
```

- Launching: follow the recipes in [launch-under-debugger.md](references/launch-under-debugger.md) — `python -m pdb`, pytest `--pdb`/`--trace`/xdist caveats, post-mortem hooks, hermetic test wrappers.
- Attaching: follow the patterns in [attach-to-running-process.md](references/attach-to-running-process.md) — debugpy listen/wait/PID-inject, terminal DAP clients, `remote-pdb` + `nc`, process shapes (child of a Node TUI, persistent worker, daemon), ptrace and forking pitfalls.
- Driving pdb: use the command reference in [inspect-state.md](references/inspect-state.md) — step/continue, conditional breakpoints, `interact`, mutating locals, threads/asyncio caveats.

## Verification Checklist

- [ ] After `pip install debugpy`, confirm: `python -c "import debugpy; print(debugpy.__version__)"`
- [ ] For remote debug, confirm the port is actually listening: `ss -tlnp | grep 5678`
- [ ] First breakpoint actually hits (if it doesn't, you likely have `PYTHONBREAKPOINT=0`, you're under xdist, or execution finished before attach)
- [ ] `where` / `w` shows the expected call stack
- [ ] Post-debug cleanup: no stray `breakpoint()` / `set_trace()` in committed code
  ```bash
  rg -n 'breakpoint\(\)|set_trace\(|debugpy\.listen' --type py
  ```
