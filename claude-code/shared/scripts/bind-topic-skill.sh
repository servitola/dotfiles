#!/usr/bin/env bash
# bind-topic-skill — give a single topic exclusive access to one skill.
#
# Replaces the bot-managed `<topic>/.claude -> ../.claude` symlink with a
# real `.claude/` dir that contains only the requested skill, isolating
# it from other topics in the same bot.
#
# Usage:
#   bind-topic-skill.sh <topic-dir> <skill-name>
#
# Examples:
#   bind-topic-skill.sh ~/projects/serho_topics/картинодел image-edit
#   bind-topic-skill.sh ~/projects/serho_topics/powerpoint  powerpoint
#
# The skill must already exist at:
#   ~/projects/dotfiles/claude-code/shared/skills/<skill-name>/

set -euo pipefail

TOPIC="${1:-}"
SKILL="${2:-}"
SHARED="$HOME/projects/dotfiles/claude-code/shared/skills"

if [[ -z "$TOPIC" || -z "$SKILL" ]]; then
  echo "usage: $0 <topic-dir> <skill-name>" >&2
  exit 64
fi

if [[ ! -d "$TOPIC" ]]; then
  echo "error: topic dir not found: $TOPIC" >&2
  exit 1
fi

if [[ ! -d "$SHARED/$SKILL" ]]; then
  echo "error: skill not found: $SHARED/$SKILL" >&2
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
ln -snf "$SHARED/$SKILL" "$CLAUDE/skills/$SKILL"

echo "bound: $TOPIC -> skill '$SKILL'"
echo "       $CLAUDE/skills/$SKILL -> $(readlink "$CLAUDE/skills/$SKILL")"
