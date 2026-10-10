# uv — global config for Astral's uv Python package/tool manager

- `.python-version` (linked to `~/.config/uv/.python-version` by install step 3) pins uv's default Python to 3.12 for `uv tool install`, `uv run` and new venvs outside a project. Without it a fresh Mac takes the newest Python uv can get, and packages without wheels for it fail: mlx-whisper on 3.15 in the VM test, while the same tool installed fine on 3.12.
- `uv.toml`: its only setting is `exclude-newer = "7 days"`: uv ignores package releases fresher than 7 days, mirroring npm's `min-release-age` — a supply-chain safety pin against just-published malicious versions.
