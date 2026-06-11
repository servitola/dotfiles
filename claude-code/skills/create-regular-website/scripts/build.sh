#!/usr/bin/env bash
# Build the site from a topic folder. Output goes to <topic>/built-site/
#
# Usage:
#   bash build.sh <topic-path>

set -euo pipefail

topic="${1:?Pass topic folder path as first argument}"
topic="$(cd "$topic" && pwd)"
engine="$topic/engine"

if [[ ! -d "$engine" ]]; then
  echo "ERROR: no engine in $topic. Run init-topic.sh first." >&2
  exit 1
fi

if [[ ! -d "$engine/node_modules" ]]; then
  echo "-> installing engine dependencies"
  (cd "$engine" && npm install --silent --no-audit --no-fund)
fi

# Prepare public/: symlink user image folders so Astro serves them at /.
public="$engine/public"
rm -rf "$public"
mkdir -p "$public"

for section in images projects gallery; do
  if [[ -d "$topic/$section" ]]; then
    ln -s "../../$section" "$public/$section"
  fi
done

# Fallback favicon if the user has not provided one.
if [[ ! -f "$topic/images/favicon.svg" ]] && [[ ! -f "$public/favicon.svg" ]]; then
  cat > "$public/favicon.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#2563eb"/></svg>
SVG
fi

echo "-> building site"
(cd "$engine" && TOPIC_ROOT="$topic" npm run build)

dist="$topic/built-site"
if [[ -d "$dist" ]]; then
  echo "OK built: $dist"
  echo "   open: file://$dist/index.html"
else
  echo "ERROR: $dist not produced" >&2
  exit 1
fi
