#!/bin/bash
# Pre-commit lint for claude-code/skills/*/SKILL.md frontmatter.
# Ensures every staged SKILL.md has non-empty `name` and `description`
# in its YAML frontmatter. Pure bash, no deps.
set -e

failed=0

for f in "$@"; do
    [ -f "$f" ] || continue

    # Extract frontmatter: lines between first two `---` markers
    frontmatter=$(awk '
        /^---[[:space:]]*$/ {
            count++
            if (count == 1) { inside = 1; next }
            if (count == 2) { exit }
        }
        inside { print }
    ' "$f")

    if [ -z "$frontmatter" ]; then
        echo "ERROR: $f — missing YAML frontmatter (--- ... ---)"
        failed=1
        continue
    fi

    # name: must be present with a non-empty value on the same line
    name_value=$(echo "$frontmatter" | awk -F: '/^name:[[:space:]]/ { sub(/^[^:]+:[[:space:]]*/, ""); print; exit }')
    if [ -z "$name_value" ]; then
        echo "ERROR: $f — frontmatter missing non-empty 'name:'"
        failed=1
    fi

    # description: present; value can be inline OR a block scalar (`|` / `>`)
    # followed by indented content on next lines.
    desc_line=$(echo "$frontmatter" | grep -E '^description:' || true)
    if [ -z "$desc_line" ]; then
        echo "ERROR: $f — frontmatter missing 'description:'"
        failed=1
        continue
    fi

    desc_inline=$(echo "$desc_line" | sed -E 's/^description:[[:space:]]*//')
    if [ -z "$desc_inline" ] || [ "$desc_inline" = "|" ] || [ "$desc_inline" = ">" ]; then
        # Block scalar — require at least one indented non-empty line after it
        has_body=$(echo "$frontmatter" | awk '
            /^description:/ { found = 1; next }
            found && /^[[:space:]]+[^[:space:]]/ { print "yes"; exit }
            found && /^[^[:space:]]/ { exit }
        ')
        if [ -z "$has_body" ]; then
            echo "ERROR: $f — 'description:' is empty"
            failed=1
        fi
    fi
done

exit $failed
