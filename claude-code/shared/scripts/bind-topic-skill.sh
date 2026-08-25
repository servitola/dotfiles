#!/usr/bin/env bash
# Give a single topic exclusive access to one skill: replaces the bot-managed
# `<topic>/.claude -> ../.claude` symlink with a real `.claude/` dir containing
# only that skill, isolating it from other topics in the same bot.
#
# Examples:
#   bind-topic-skill.sh ~/projects/serho_topics/картинодел image-edit
#   bind-topic-skill.sh ~/projects/serho_topics/powerpoint  powerpoint

set -euo pipefail

TOPIC="${1:-}"
SKILL="${2:-}"

if [[ -z "$TOPIC" || -z "$SKILL" ]]; then
  echo "usage: $0 <topic-dir> <skill-name>" >&2
  exit 64
fi

if [[ ! -d "$TOPIC" ]]; then
  echo "error: topic dir not found: $TOPIC" >&2
  exit 1
fi

SRC=""
for base in \
  "$HOME/projects/dotfiles/claude-code/skills" \
  "$HOME/projects/dotfiles/claude-code/detached_skills"; do
  if [[ -d "$base/$SKILL" ]]; then SRC="$base/$SKILL"; break; fi
done

if [[ -z "$SRC" ]]; then
  echo "error: skill not found in any source: $SKILL" >&2
  exit 1
fi

CLAUDE="$TOPIC/.claude"

# Drop the bot-managed symlink (or any prior install) and rebuild.
if [[ -L "$CLAUDE" ]]; then
  rm "$CLAUDE"
elif [[ -d "$CLAUDE" ]]; then
  echo "note: $CLAUDE is already a real dir; reusing"
fi

mkdir -p "$CLAUDE/skills"
ln -snf "$SRC" "$CLAUDE/skills/$SKILL"

echo "bound: $TOPIC -> skill '$SKILL'"
echo "       $CLAUDE/skills/$SKILL -> $(readlink "$CLAUDE/skills/$SKILL")"
