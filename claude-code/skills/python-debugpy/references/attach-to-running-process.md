# Attach to a Running Process

Remote debug with debugpy or remote-pdb: long-lived processes — a server, a gateway, a daemon, a process that's already misbehaving and can't be restarted clean.

## Contents

- [Setup](#setup)
- [Pattern A: Source-edit — process waits for debugger at launch](#pattern-a-source-edit--process-waits-for-debugger-at-launch)
- [Pattern B: No source edit — launch with `-m debugpy`](#pattern-b-no-source-edit--launch-with--m-debugpy)
- [Pattern C: Attach to an already-running process](#pattern-c-attach-to-an-already-running-process)
- [Connecting a client from the terminal](#connecting-a-client-from-the-terminal)
- [Debugging common process shapes](#debugging-common-process-shapes)
- [Pitfalls](#pitfalls)
- [One-shot recipe: async handler deadlocks](#one-shot-recipe-async-handler-deadlocks)

## Setup

```bash
source .venv/bin/activate
pip install debugpy
```

## Pattern A: Source-edit — process waits for debugger at launch

Add near the top of the entry point (or inside the function you want to debug):

```python
import debugpy
debugpy.listen(("127.0.0.1", 5678))
print("debugpy listening on 5678, waiting for client...", flush=True)
debugpy.wait_for_client()
debugpy.breakpoint()       # optional: pause immediately once attached
```

Start the process; it blocks on `wait_for_client()`.

## Pattern B: No source edit — launch with `-m debugpy`

```bash
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client your_script.py arg1
```

Equivalent for module entry:

```bash
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client -m your.module
```

## Pattern C: Attach to an already-running process

Needs the PID and debugpy preinstalled in the target's environment:

```bash
python -m debugpy --listen 127.0.0.1:5678 --pid <pid>
# debugpy injects itself into the process. Then attach a client as below.
```

Some kernels/security configs block the ptrace-based injection (`/proc/sys/kernel/yama/ptrace_scope`). Fix with:
```bash
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
```

## Connecting a client from the terminal

The easiest terminal-side DAP client is VS Code CLI or a small script. From a terminal you have two practical options:

**Option 1: `debugpy`'s own CLI REPL** — not an official feature, but a tiny DAP client script:

```python
# /tmp/dap_client.py
import socket, json, itertools, time, sys

HOST, PORT = "127.0.0.1", 5678
s = socket.create_connection((HOST, PORT))
seq = itertools.count(1)

def send(msg):
    msg["seq"] = next(seq)
    body = json.dumps(msg).encode()
    s.sendall(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)

def recv():
    header = b""
    while b"\r\n\r\n" not in header:
        header += s.recv(1)
    length = int(header.decode().split("Content-Length:")[1].split("\r\n")[0].strip())
    body = b""
    while len(body) < length:
        body += s.recv(length - len(body))
    return json.loads(body)

send({"type": "request", "command": "initialize", "arguments": {"adapterID": "python"}})
print(recv())
send({"type": "request", "command": "attach", "arguments": {}})
print(recv())
send({"type": "request", "command": "setBreakpoints",
      "arguments": {"source": {"path": sys.argv[1]},
                    "breakpoints": [{"line": int(sys.argv[2])}]}})
print(recv())
send({"type": "request", "command": "configurationDone"})
# ... loop reading events and sending continue/stepIn/etc.
```

This is fine for one-off automation but painful as an interactive UX.

**Option 2: Attach from VS Code / Cursor / Zed** — if the user has one open, they can add a `launch.json`:

```json
{
  "name": "Attach to process",
  "type": "debugpy",
  "request": "attach",
  "connect": { "host": "127.0.0.1", "port": 5678 },
  "justMyCode": false,
  "pathMappings": [
    { "localRoot": "${workspaceFolder}", "remoteRoot": "/path/to/project/on/host" }
  ]
}
```

**Option 3: Ditch DAP, use `remote-pdb`** — usually what you actually want from a terminal agent:

```bash
pip install remote-pdb
```

In your code:
```python
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)   # blocks until connection
```

Then from the terminal:
```bash
nc 127.0.0.1 4444
# You get a (Pdb) prompt exactly as if debugging locally.
```

`remote-pdb` is the cleanest agent-friendly choice when `debugpy`'s DAP protocol is overkill. Use `debugpy` only when you actually need IDE integration.

## Debugging common process shapes

### A backend subprocess spawned by another process (e.g. a Node TUI)
When a Python backend runs as a child of another process, you can't easily launch it under a debugger. Two options:

**A. Source-edit the server's entry point:**
```python
# near the top of serve()
import debugpy
debugpy.listen(("127.0.0.1", 5678))
debugpy.wait_for_client()
```
Start the parent app. Its UI will appear frozen (the backend is waiting). Attach a client; execution resumes when you `continue`.

**B. Use `remote-pdb` at a specific handler:**
```python
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)   # in the RPC handler you want to trap
```
Trigger the action that hits that handler, then `nc 127.0.0.1 4444` in another terminal.

### A persistent worker subprocess
Same pattern — `remote-pdb` with `set_trace()` inside the worker's `exec` path. A persistent worker blocks on the first trigger until you connect; subsequent calls pass through normally unless you re-arm.

### A long-lived gateway / daemon
Use `remote-pdb` at a handler, or `debugpy` with `--wait-for-client` if you're restarting the process anyway.

## Pitfalls

1. **`debugpy.listen` blocks only if you also call `wait_for_client()`.** Without it, execution continues and your first breakpoint may fire before the client is attached.

2. **Attach to PID fails on hardened kernels.** `ptrace_scope=1` (Ubuntu default) allows only same-user ptrace of child processes. Workaround: `echo 0 > /proc/sys/kernel/yama/ptrace_scope` (needs root) or launch under `debugpy` from the start.

3. **Forking / multiprocessing.** pdb does not follow forks. Each child needs its own `breakpoint()` or `set_trace()`. Debug one process at a time.

## One-shot recipe: async handler deadlocks

```python
# Add at handler entry
import remote_pdb; remote_pdb.set_trace(host="127.0.0.1", port=4444)
```
Trigger the handler. `nc 127.0.0.1 4444`, then `w` to see the suspended frame, `!import asyncio; asyncio.all_tasks()` to see what else is pending.
