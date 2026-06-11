---
name: node-inspect-debugger
description: |
  Debug Node.js programmatically from the terminal via --inspect and the Chrome DevTools Protocol.

  Use when: "отладь node", "поставь брейкпоинт в node", "почему тут undefined в node", "debug node.js", "set a breakpoint in node", "attach a debugger to node"
---

# Node.js Inspect Debugger

## Overview

When `console.log` isn't enough, drive Node's built-in V8 inspector programmatically from the terminal. You get real breakpoints, step in/over/out, call-stack walking, local/closure scope dumps, and arbitrary expression evaluation in the paused frame.

Two tools, pick one:

| Tool | When |
|---|---|
| **`node inspect`** | Built-in, zero install, CLI REPL. Best for quick poking. |
| **`ndb` / CDP via `chrome-remote-interface`** | Scriptable from Node/Python; best when you want to automate many breakpoints, collect state across runs, or debug non-interactively from an agent loop. Also the path to heap snapshots and CPU profiles. |

**Prefer `node inspect` first.** It's always available and the REPL is fast.

## When to Use

- A Node test fails and you need to see intermediate state
- A React/Ink TUI crashes or behaves wrong and you want to inspect state pre-render
- Child processes (worker threads, PTY bridge workers) misbehave
- You need to inspect a value in a closure that `console.log` can't reach without patching
- Perf: attach to a running process to capture a CPU profile or heap snapshot

**Don't use for:** things `console.log` solves in under a minute. Breakpoint-driven debugging is heavier; use it when the payoff is real. If the misbehaving subprocess is Python rather than Node, use the `python-debugpy` skill for it — only the Node portions (Ink UI, client code, tsx-run tests) use this skill.

## Happy Path: `node inspect`

Launch paused on first line:

```bash
node inspect path/to/script.js
# or with tsx
node --inspect-brk $(which tsx) path/to/script.ts
```

At the `debug>` prompt:

```
sb('script.js', 42)   # breakpoint at line 42
cont                  # run to it
repl                  # REPL in the paused scope (Ctrl+C exits back to debug>)
> myVariable
```

Drive the prompt with the full command table in [inspect-state.md](references/inspect-state.md).

## What do you need?

Load the smallest set of references that fits the task — usually exactly one branch.

```
Launch something under a debugger?
├─ Script / TS entry, paused on first line      → launch-under-debugger.md
├─ Ink + tsx TUI you can rebuild and restart    → launch-under-debugger.md
└─ Vitest / jest test under the debugger        → launch-under-debugger.md

Attach to an already-running process?
├─ Dev server / gateway / daemon (SIGUSR1)      → attach-to-running-process.md
├─ TUI spawned by another process               → attach-to-running-process.md
├─ Scripted CDP (many breakpoints, agent loop)  → attach-to-running-process.md
└─ Heap snapshot / CPU profile                  → attach-to-running-process.md

Inside a `debug>` prompt already?
└─ Stepping, breakpoints, scope, recipes        → inspect-state.md
```

- Launching: follow the recipes in [launch-under-debugger.md](references/launch-under-debugger.md) — inspector flags (`--inspect` / `--inspect-brk` / custom port), tsx, Ink TUI builds, vitest/jest single-worker runs, sourcemap / child-process / security pitfalls.
- Attaching: follow the patterns in [attach-to-running-process.md](references/attach-to-running-process.md) — SIGUSR1 on a live PID, attach by PID or ws URL, programmatic CDP driver script, heap snapshots and CPU profiles, port collisions.
- Driving the REPL: use the command reference in [inspect-state.md](references/inspect-state.md) — step/continue, breakpoints, watch, `repl` sub-mode, one-shot recipes, paused-target and PTY caveats.

## Verification Checklist

After setting up a debug session, verify:

- [ ] `curl -s http://127.0.0.1:9229/json/list` returns exactly the target you expect
- [ ] First breakpoint actually hits (if it doesn't, you likely missed `--inspect-brk` or attached after execution completed)
- [ ] Source listing at pause shows the right file (mismatch = sourcemap issue, see pitfalls in [launch-under-debugger.md](references/launch-under-debugger.md))
- [ ] `exec process.pid` in `repl` returns the PID you meant to attach to
