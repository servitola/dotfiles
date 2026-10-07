#!/bin/zsh
# Build karabiner.json from template + individual rule files
# Usage: ./build.sh

# -P: ~/.config/karabiner is a symlink to this directory, and the generator lives beside it in the repo.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
TEMPLATE="$SCRIPT_DIR/karabiner-template.json"
RULES_DIR="$SCRIPT_DIR/rules"
OUTPUT="$SCRIPT_DIR/karabiner.json"

if [ ! -f "$TEMPLATE" ]; then
    echo "Error: karabiner-template.json not found"
    exit 1
fi

if [ ! -d "$RULES_DIR" ] || [ -z "$(ls "$RULES_DIR"/*.json 2>/dev/null)" ]; then
    echo "Error: no rule files found in rules/"
    exit 1
fi

python3 "$SCRIPT_DIR/../docs/keyboard/tools/gen_layers.py" || exit 1

jq '.profiles[0].complex_modifications.rules = [inputs]' \
    "$TEMPLATE" \
    "$RULES_DIR"/*.json \
    > "$OUTPUT.tmp" && mv "$OUTPUT.tmp" "$OUTPUT"

rule_count=$(jq '.profiles[0].complex_modifications.rules | length' "$OUTPUT")
manip_count=$(jq '[.profiles[0].complex_modifications.rules[].manipulators | length] | add' "$OUTPUT")
echo "Built karabiner.json: $rule_count rules, $manip_count manipulators"

HELPER="$SCRIPT_DIR/helper/keylog"
if [ ! -x "$HELPER" ] || [ "$HELPER.c" -nt "$HELPER" ]; then
    cc -O2 -Wall -o "$HELPER" "$HELPER.c"
fi
python3 "$SCRIPT_DIR/instrument.py" "$OUTPUT"
