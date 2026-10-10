#!/bin/zsh
# Generate the Brewfile `mas` block by detecting Mac App Store apps directly.
#
# Why this exists: mas 2.x enumerates installed App Store apps through the
# Spotlight index, which is disabled on this machine (`mdutil -s /` → off). So
# `mas list` returns nothing and `brew bundle dump` (which shells out to it)
# silently drops every `mas` line from the brewfile.
#
# Instead we detect App Store apps structurally — every one of them carries a
# `Contents/_MASReceipt/receipt` inside its bundle (Homebrew casks and
# hand-downloaded apps do not). The app name is the bundle's own name (matching
# what `mas`/`brew bundle dump` historically wrote — the local short name, not
# the verbose App Store title); only the numeric track id needs resolving, which
# we do from the app's CFBundleIdentifier via the public iTunes Lookup API.
# Resolved ids are cached in `mas-cache.tsv` (committed) so offline `up` runs
# still emit the full, stable list; only a freshly-installed App Store app needs
# one network lookup.
#
# Used by macos_update/update_all.sh: `brew bundle dump` runs with --no-mas and
# this script's stdout is appended to the brewfile.
#
# stdout: Brewfile mas lines, alphabetical:  mas "Name", id: 123456789

# zsh, not bash: macOS ships bash 3.2, which has no associative arrays, and a
# fresh Mac has no Homebrew bash yet.
setopt no_unset

APPS_DIR="/Applications"
CACHE="${0:a:h}/mas-cache.tsv"

# --- load cache: bundleId -> id (name re-read from cache at emit time) -------
typeset -A CACHE_ID
if [[ -f "$CACHE" ]]; then
    while IFS=$'\t' read -r bid id _name; do
        [[ -n "$bid" ]] || continue
        CACHE_ID[$bid]="$id"
    done < "$CACHE"
fi

# --- detect installed App Store apps, resolve ids ---------------------------
typeset -A OUT_ID OUT_NAME
for app in "$APPS_DIR"/*.app(N); do
    [[ -e "$app/Contents/_MASReceipt/receipt" ]] || continue
    bid=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null) || continue
    [[ -n "$bid" ]] || continue
    name=$(basename "$app" .app)

    if [[ -n "${CACHE_ID[$bid]:-}" ]]; then
        id="${CACHE_ID[$bid]}"
    else
        # Resolve the numeric track id from the bundle id. No `entity=macSoftware`
        # filter on purpose: universal apps report kind "software" (TestFlight) or
        # "mac-software" (Day One) and the entity filter silently drops them.
        resp=$(curl -fsS "https://itunes.apple.com/lookup?bundleId=${bid}&country=us" 2>/dev/null) || resp=""
        id=$(printf '%s' "$resp" | /usr/bin/python3 -c '
import sys, json
try:
    r = (json.load(sys.stdin).get("results") or [])
    if r:
        print(r[0]["trackId"])
except Exception:
    pass
')
        if [[ -z "${id:-}" ]]; then
            echo "  * mas-dump: could not resolve track id for $name ($bid) — skipping" >&2
            continue
        fi
    fi
    OUT_ID[$bid]="$id"
    OUT_NAME[$bid]="$name"
done

# --- rewrite cache (pruned to installed set, sorted by name) ----------------
tmp="$CACHE.tmp"
: > "$tmp"
for bid in "${(@k)OUT_ID}"; do
    printf '%s\t%s\t%s\n' "$bid" "${OUT_ID[$bid]}" "${OUT_NAME[$bid]}"
done | sort -t$'\t' -k3,3 -f > "$tmp"
mv "$tmp" "$CACHE"

# --- emit the Brewfile block ------------------------------------------------
while IFS=$'\t' read -r bid id name; do
    printf 'mas "%s", id: %s\n' "$name" "$id"
done < "$CACHE"
