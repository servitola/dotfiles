# annepro2 — Anne Pro 2 (60%) mechanical keyboard config: key layout + RGB lighting

Hardware note: this unit is **Anne Pro C18** (not C15). Config is exported from / imported into ObinsKit, the vendor GUI.

- `layout.json` — ObinsKit keymap export (3 layers as USB HID keycode arrays + per-key tap flags)
- `lightning.json` — RGB lighting profile (per-key static colors + dynamic effect palette)
- ObinsKit (the only tool that reads/writes these JSONs over Bluetooth/USB) is NOT vendored here — download v1.2.11 from the vendor (hexcore.xyz / obins archive). The installer used to be committed (~80 MB) but was purged from history to keep the repo light.
- Relation to the rest of the repo: this is **physical-keyboard firmware** state, independent from the macOS-side keyboard system (`karabiner/`, `keyboard-layout/Birman.bundle/`, `hammerspoon/Spoons/HotKeys.spoon/`). Those remap whatever the OS receives; this defines what the Anne Pro itself sends. No symlinks, no Makefile wiring — manual ObinsKit import only.
