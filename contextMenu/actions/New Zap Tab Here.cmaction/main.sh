#!/bin/zsh
# Opens path in Zap via launch_configurations + zap:// URL scheme.
# NOTE: Zap's URL scheme only supports opening a new WINDOW, not a tab in the
# existing window. There is no console-only way to add a tab to a running Zap
# instance — the only mechanism would be synthesized keystrokes (Cmd+T), which
# we intentionally avoid.

target="$1"
if [ ! -d "$target" ]; then
    target="$(dirname "$target")"
fi

dir_escaped="${target//\"/\\\"}"
config_dir="$HOME/.zap/launch_configurations"
config_name="_context_menu"

mkdir -p "$config_dir"
cat > "$config_dir/${config_name}.yaml" <<YAML
name: ${config_name}
active_window_index: 0
windows:
  - active_tab_index: 0
    tabs:
      - layout:
          cwd: "${dir_escaped}"
          is_focused: true
YAML

open "zap://launch/${config_name}"
