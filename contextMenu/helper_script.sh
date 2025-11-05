#!/bin/zsh
scripts_dir=~/Library/Application\ Scripts/net.langui.ContextMenuHelper
mkdir -p "$scripts_dir"
script_content=$'#!/bin/sh\npkill -nf ScriptMonitor\nexec "$@"'
helper_path="$scripts_dir/contextmenu.sh"
echo "$script_content" > "$helper_path"
chmod +x "$helper_path"
