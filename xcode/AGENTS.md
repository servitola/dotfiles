# xcode — Xcode IDE config: custom key bindings, symlinked into Xcode's UserData

- `install.sh` — ensures Xcode CLI tools are present, then symlinks the whole `KeyBindings/` dir into `~/Library/Developer/Xcode/UserData/KeyBindings` (removes any existing target first). Run via the dotfiles installer, not standalone.
