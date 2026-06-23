# docs — human/agent reference docs for the dotfiles setup, read selectively

- These are reference docs, not config — read the specific file relevant to a question rather than ingesting the whole tree. The live source of truth is the actual config dirs (`hammerspoon/`, `karabiner/`, `homebrew/`, the `Makefile`); docs describe and orient.
- `README.md` — top-level index linking every doc (shell, keyboard, editors, terminal, git, homebrew); start here to find the right page.
- `keyboard-setup.md` — the keyboard system: Karabiner-Elements remapping (Caps Lock → Hyper = all 4 right modifiers), the Birman custom layout, and Hammerspoon catching key events to launch apps/run functions. Source-of-truth pipeline: karabiner → birman → hammerspoon.
- `hammerspoon.md` — Hammerspoon automation: Spoon system, HotKeys spoon, Lua scripting against macOS APIs.
- `app-integration.md` — checklist for wiring a new app into the repo: create `dotfiles/{app}/` dir, then add Makefile symlink commands (`REMOVE`/`LINK`/`COPY` vars) to the `install` target. Read before adding any new app config.
- `homebrew.md` — package management notes; points at `homebrew/brewfile` and install scripts as the real data.
- `keyboard/` — auto-generated SVG layer diagrams (one per modifier combination) plus `README.md` legend. Regenerate, do not hand-edit, via `python3 docs/keyboard/generate.py`.
- `keyboard/` Python modules build the SVGs from config (`parse_karabiner.py`, `parse_birman.py`, `svg_*.py`, etc.); `keyboard/tools/` holds `lint.py` (format/coverage checks on the HotKeys layout `.lua`) and `normalize.py` (rewrite layout files to canonical ASCII). Run these against the Hammerspoon layout, not against the docs.
