# Inspect State (pdb Commands)

Stepping, breakpoints, and state inspection inside any pdb prompt — local `breakpoint()`, `python -m pdb`, `remote-pdb` over `nc`, post-mortem.

## Command reference

Inside any pdb prompt (`(Pdb)`):

| Command | Action |
|---|---|
| `h` / `h cmd` | help |
| `n` | next line (step over) |
| `s` | step into |
| `r` | return from current function |
| `c` | continue |
| `unt N` | continue until line N |
| `j N` | jump to line N (same function only) |
| `l` / `ll` | list source around current line / full function |
| `w` | where (stack trace) |
| `u` / `d` | move up / down in the stack |
| `a` | print args of the current function |
| `p expr` / `pp expr` | print / pretty-print expression |
| `display expr` | auto-print expr on every stop |
| `b file:line` | set breakpoint |
| `b func` | break on function entry |
| `b file:line, cond` | conditional breakpoint |
| `cl N` | clear breakpoint N |
| `tbreak file:line` | one-shot breakpoint |
| `!stmt` | execute arbitrary Python (assignments included) |
| `interact` | drop into full Python REPL in current scope (Ctrl+D to exit) |
| `q` | quit |

The `interact` command is the most powerful — you can import anything, inspect complex objects, even call methods that mutate state. Locals are read-only by default; use `!x = 42` from the `(Pdb)` prompt to mutate.

## Pitfalls

1. **Threads.** `pdb` only debugs the current thread. For multithreaded code, use `debugpy` (thread-aware DAP) or set `threading.settrace()` per thread.

2. **asyncio.** `pdb` works in coroutines but `await` inside pdb requires Python 3.13+ or `await` from `interact` mode on older versions. For 3.11/3.12, use `asyncio.run_coroutine_threadsafe` tricks or `!stmt`-based awaits via `asyncio.ensure_future`.

## One-shot recipe: "Why is this dict missing a key?"

```python
# add above the KeyError site
breakpoint()
# then in pdb:
(Pdb) pp d
(Pdb) pp list(d.keys())
(Pdb) w                # how did we get here
```
