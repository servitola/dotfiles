#!/usr/bin/env bash
# Updates the engine in an existing topic to the current template version,
# WITHOUT touching user content (posts/, projects/, gallery/, images/,
# site.yaml, links.yaml, home.md, about.md).
#
# Usage:
#   bash update-engine.sh <topic-path>

set -euo pipefail

topic="${1:?Pass topic folder path as first argument}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(dirname "$script_dir")"
template="$skill_dir/topic-template"

if [[ ! -d "$topic" ]]; then
  echo "ERROR: $topic does not exist" >&2
  exit 1
fi

if [[ ! -f "$topic/site.yaml" ]]; then
  echo "ERROR: $topic has no site.yaml — not a site topic" >&2
  exit 1
fi

echo "-> updating engine"

rm -rf "$topic/engine"
cp -r "$template/engine" "$topic/engine"

cp "$template/.gitignore" "$topic/.gitignore"

echo "-> reinstalling dependencies"
(cd "$topic/engine" && npm install --silent --no-audit --no-fund)

echo "OK engine updated. Content untouched."
