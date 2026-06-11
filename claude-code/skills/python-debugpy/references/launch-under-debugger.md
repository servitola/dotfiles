# Launch Under a Debugger

Starting a script, module, or test under pdb — no source edits, or post-mortem after a crash.

## Launch a script under pdb (no source edits)

```bash
python -m pdb path/to/script.py arg1 arg2
# Lands at first line of script
(Pdb) b path/to/script.py:42
(Pdb) c
```

## Debug a pytest test

```bash
# Drop to pdb on failure (or on any raised exception):
python -m pytest tests/path/to/test_file.py::test_name --pdb

# Drop to pdb at the START of the test:
python -m pytest tests/path/to/test_file.py::test_name --trace

# Show locals in tracebacks without pdb:
python -m pytest tests/path/to/test_file.py --showlocals --tb=long
```

Note: if your test runner uses pytest-xdist (`-n 4`) by default, pdb does NOT work under xdist. Add `-p no:xdist` or run a single test with `-n 0`:

```bash
source .venv/bin/activate
python -m pytest tests/foo_test.py::test_bar --pdb -p no:xdist
```

If your project wraps pytest in a test script that strips the environment (e.g. a hermetic runner), debugging with raw `pytest` bypasses those guarantees — fine for debugging, but re-run under the wrapper to confirm before pushing.

## Post-mortem on any exception

```python
import pdb, sys
try:
    run_the_thing()
except Exception:
    pdb.post_mortem(sys.exc_info()[2])
```

Or wrap a whole script:

```bash
python -m pdb -c continue script.py
# When it crashes, pdb catches it and you're in the frame of the exception
```

Or set a global hook in a repl/jupyter:

```python
import sys
def excepthook(etype, value, tb):
    import pdb; pdb.post_mortem(tb)
sys.excepthook = excepthook
```

## Pitfalls

1. **pdb under pytest-xdist silently does nothing.** You won't see the prompt, the test just hangs. Always use `-p no:xdist` or `-n 0`.

2. **Hermetic test wrappers strip credentials and reset `HOME`.** If your project's test runner sandboxes the environment, a bug that depends on user config or real API keys won't reproduce under the wrapper. Debug with raw `pytest` first to repro, then re-confirm under the wrapper.

## One-Shot Recipes

**"This test passes in isolation but fails in the suite."**
```bash
source .venv/bin/activate
python -m pytest tests/the_test.py --pdb -p no:xdist
# But if it only fails WITH other tests:
python -m pytest tests/ -x --pdb -p no:xdist
# Now it pdb-traps at the exact failing test after state accumulated.
```

**"Post-mortem on a crash in a child process / subprocess."**
```bash
PYTHONFAULTHANDLER=1 python -m pdb -c continue path/to/entrypoint.py
# On crash, pdb lands at the frame of the exception with full locals
```
