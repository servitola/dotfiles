# Launch Under a Debugger

Starting a script, a TypeScript entry, an Ink TUI build, or a test run with the inspector enabled from the first line.

## Inspector flags

To start a process with the inspector from the beginning:

```bash
node --inspect script.js           # listen on 127.0.0.1:9229, keep running
node --inspect-brk script.js       # listen AND pause on first line
node --inspect=0.0.0.0:9230 script.js   # custom host:port
```

## TypeScript via tsx

```bash
node --inspect-brk --import tsx script.ts
# or older tsx
node --inspect-brk -r tsx/cjs script.ts
# or run the tsx binary under the inspector
node --inspect-brk $(which tsx) path/to/script.ts
```

## Debugging a single Ink component under dev

If the project has `npm run dev` (tsx --watch), add `--inspect-brk` by running the built entry directly:

```bash
cd /path/to/your-tui
npm run build    # produce dist/ once so transpile isn't needed on first load
node --inspect-brk dist/entry.js
# In another terminal:
node inspect -p <node pid>
```

Then inside `debug>`:

```
sb('dist/app.js', 220)     # or wherever the suspect render is
cont
```

When it pauses, `repl` → inspect `props`, state refs, `useInput` handler values, etc.

## Running Vitest tests under the debugger

```bash
cd /path/to/your-project
# Run a single test file paused on entry
node --inspect-brk ./node_modules/vitest/vitest.mjs run --no-file-parallelism src/app/foo.test.tsx
```

In another terminal: `node inspect -p <pid>`, then `sb('src/app/foo.tsx', 42)`, `cont`.

Use `--no-file-parallelism` (vitest) or `--runInBand` (jest) so only one worker exists — debugging a pool is painful.

## Pitfalls

1. **Wrong line numbers in TS source.** Breakpoints hit the emitted JS, not the `.ts`. Either (a) break in the built `dist/*.js`, or (b) enable sourcemaps (`node --enable-source-maps`) and use `sb('src/app.tsx', N)` — but only with CDP clients that follow sourcemaps. `node inspect` CLI does not.

2. **`--inspect` vs `--inspect-brk`.** `--inspect` starts the inspector but doesn't pause; your script races past your first breakpoint if you attach too late. Use `--inspect-brk` when you need to set breakpoints before any code runs.

3. **Child processes.** `--inspect` on a parent does NOT inspect its children. Use `NODE_OPTIONS='--inspect-brk' node parent.js` to propagate to every child; be aware they all need unique ports (Node auto-increments when `NODE_OPTIONS='--inspect'` is inherited).

4. **Security.** `--inspect=0.0.0.0:9229` exposes arbitrary code execution. Always bind to `127.0.0.1` (the default) unless you have an isolated network.
