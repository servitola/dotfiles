#!/bin/zsh
# Build karabiner.json from template + individual rule files
# Usage: ./build.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

jq '.profiles[0].complex_modifications.rules = [inputs]' \
    "$TEMPLATE" \
    "$RULES_DIR"/*.json \
    > "$OUTPUT.tmp" && mv "$OUTPUT.tmp" "$OUTPUT"

rule_count=$(jq '.profiles[0].complex_modifications.rules | length' "$OUTPUT")
manip_count=$(jq '[.profiles[0].complex_modifications.rules[].manipulators | length] | add' "$OUTPUT")
echo "Built karabiner.json: $rule_count rules, $manip_count manipulators"
