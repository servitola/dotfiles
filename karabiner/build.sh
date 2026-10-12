#!/bin/zsh
# -P: ~/.config/karabiner is a symlink to this directory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

python3 "$SCRIPT_DIR/generator/gen_rules.py" || exit 1

HELPER="$SCRIPT_DIR/helper/keylog"
if [ ! -x "$HELPER" ] || [ "$HELPER.c" -nt "$HELPER" ]; then
    cc -O2 -Wall -o "$HELPER" "$HELPER.c"
fi
python3 "$SCRIPT_DIR/instrument.py" "$SCRIPT_DIR/karabiner.json"
