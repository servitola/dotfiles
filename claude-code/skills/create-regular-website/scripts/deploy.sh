#!/usr/bin/env bash
# Build the site and publish to Surge.sh.
#
# Usage:
#   bash deploy.sh <topic-path> [--preview]
#
# --preview deploys to <slug>-preview.surge.sh (production untouched).
# Production domain = <slug>.surge.sh, where <slug> is the transliterated
# topic folder name.
#
# Requires SURGE_LOGIN (email) and SURGE_TOKEN (from `surge token`) in
# the environment or in ~/.config/openai_key.sh.

set -euo pipefail

if [[ -z "${SURGE_LOGIN:-}" || -z "${SURGE_TOKEN:-}" ]] && [[ -f "$HOME/.config/openai_key.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/openai_key.sh"
fi

if [[ -z "${SURGE_LOGIN:-}" || -z "${SURGE_TOKEN:-}" ]]; then
  echo "ERROR: SURGE_LOGIN and SURGE_TOKEN must be set." >&2
  echo "       Get a token via 'npx surge token' once, then add both to" >&2
  echo "       ~/.config/openai_key.sh as:" >&2
  echo "         export SURGE_LOGIN='you@example.com'" >&2
  echo "         export SURGE_TOKEN='...'" >&2
  exit 1
fi

export SURGE_LOGIN SURGE_TOKEN

topic="${1:?Pass topic folder path as first argument}"
shift || true
mode="production"
for arg in "$@"; do
  case "$arg" in
    --preview) mode="preview" ;;
  esac
done

topic="$(cd "$topic" && pwd)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Surge subdomain: slug of the topic folder name.
# Cyrillic → transliterated; only [a-z0-9-] kept.
topic_name="$(basename "$topic")"
slug="$(echo "$topic_name" | python3 -c '
import sys, re
s = sys.stdin.read().strip().lower()
tr = str.maketrans({
    "а":"a","б":"b","в":"v","г":"g","д":"d","е":"e","ё":"yo","ж":"zh",
    "з":"z","и":"i","й":"y","к":"k","л":"l","м":"m","н":"n","о":"o",
    "п":"p","р":"r","с":"s","т":"t","у":"u","ф":"f","х":"h","ц":"ts",
    "ч":"ch","ш":"sh","щ":"sch","ъ":"","ы":"y","ь":"","э":"e","ю":"yu","я":"ya",
    " ":"-","_":"-",
})
s = s.translate(tr)
s = re.sub(r"[^a-z0-9-]", "", s)
s = re.sub(r"-+", "-", s).strip("-")
print(s or "site")
')"

if [[ "$mode" == "production" ]]; then
  domain="$slug.surge.sh"
else
  domain="$slug-preview.surge.sh"
fi

bash "$script_dir/build.sh" "$topic"

dist="$topic/built-site"
if [[ ! -d "$dist" ]]; then
  echo "ERROR: $dist not found after build" >&2
  exit 1
fi

echo "-> deploying to $domain (mode: $mode)"

# surge reads SURGE_LOGIN/SURGE_TOKEN from env for non-interactive auth.
npx --yes surge "$dist" "$domain"

public_url="https://$domain"

echo ""
echo "OK published"
echo "   URL: $public_url"
