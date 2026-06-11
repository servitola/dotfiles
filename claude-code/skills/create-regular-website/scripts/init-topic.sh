#!/usr/bin/env bash
# Initialize a topic folder as a website: copy template + install deps.
#
# Usage:
#   bash init-topic.sh <topic-path>
#
# Safe to re-run — never overwrites existing user content.

set -euo pipefail

topic="${1:?Pass topic folder path as first argument}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(dirname "$script_dir")"
template="$skill_dir/topic-template"

if [[ ! -d "$topic" ]]; then
  echo "ERROR: topic folder $topic does not exist" >&2
  exit 1
fi

if [[ ! -d "$template" ]]; then
  echo "ERROR: template $template not found" >&2
  exit 1
fi

echo "-> copying template into $topic"

rsync -a --ignore-existing \
  --exclude 'node_modules' \
  --exclude 'built-site' \
  --exclude '.astro' \
  "$template"/ "$topic"/

# Pre-create empty content folders so the AI sees the structure right away.
for d in posts images projects gallery; do
  mkdir -p "$topic/$d"
done

# Install engine dependencies on first init.
engine="$topic/engine"
if [[ ! -d "$engine/node_modules" ]]; then
  echo "-> installing engine dependencies (one-time, ~30 seconds)"
  (cd "$engine" && npm install --silent --no-audit --no-fund)
fi

echo "OK topic initialised"
echo ""
echo "Layout:"
echo "  site.yaml       - settings"
echo "  links.yaml      - socials"
echo "  home.md         - hero text"
echo "  about.md        - about page"
echo "  posts/          - blog posts (.md)"
echo "  projects/       - portfolio (one folder per project)"
echo "  gallery/        - photo albums (one folder per album)"
echo "  images/         - shared images"
echo "  engine/         - internal, do not edit"
