#!/bin/zsh

echo
echo "📦 Installing/updating global npm packages..."

PACKAGES_FILE=~/projects/dotfiles/npm/global-packages.txt

# "@scope/name@1.2.3" -> "@scope/name";  "name@1.2.3" -> "name"
spec_name() {
    local spec="$1"
    if [[ "$spec" == @* ]]; then
        echo "@${${spec#@}%%@*}"
    else
        echo "${spec%%@*}"
    fi
}

spec_version() {
    local spec="$1" name
    name="$(spec_name "$spec")"
    [[ "$spec" == "$name" ]] && return
    echo "${spec#${name}@}"
}

# npm refuses versions younger than min-release-age days, so "newest" means newest of those.
release_age=$(npm config get min-release-age)
[[ $release_age == <-> ]] || release_age=0
allowed_version() {
    npm view "$1" time --json 2>/dev/null | jq -r --argjson days "$release_age" '
        to_entries
        | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
        | map(select((.value | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) <= now - $days * 86400))
        | sort_by(.value) | last | .key // empty'
}

installed_version() {
    npm list -g "$1" --depth=0 --json 2>/dev/null \
        | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4
}

safe_npm_update() {
    local package_dir="$HOME/.npm-global/lib/node_modules/$(spec_name "$1")"

    if [ -d "$package_dir" ]; then
        xattr -cr "$package_dir" 2>/dev/null || true
    fi

    npm install -g "$1" 2>&1 | grep -v "^npm warn"
    return $pipestatus[1]
}

typeset -A pins

while IFS= read -r spec || [ -n "$spec" ]; do
    [[ -z "$spec" ]] && continue
    [[ "$spec" =~ ^[[:space:]]*# ]] && continue

    name="$(spec_name "$spec")"
    pinned="$(spec_version "$spec")"
    [[ -n "$pinned" ]] && pins[$name]="$spec"

    current_version="$(installed_version "$name")"

    if [ -n "$pinned" ]; then
        target_version="$pinned"
    else
        target_version="$(allowed_version "$name")"
    fi

    if [ -z "$target_version" ]; then
        echo "⚠️  Cannot resolve a version for: $name"
        continue
    fi

    [ "$current_version" = "$target_version" ] && continue

    if [ -z "$current_version" ]; then
        echo "📥 Installing: $name@$target_version"
    elif [ -n "$pinned" ]; then
        echo "📌 Pinning: $name ($current_version → $target_version)"
    else
        echo "🔄 Updating: $name ($current_version → $target_version)"
    fi

    if safe_npm_update "$name@$target_version"; then
        echo "✅ Ready: $name@$target_version"
    else
        echo "❌ Failed: $name@$target_version"
    fi
done < "$PACKAGES_FILE"

echo "💾 Saving current global packages list..."
npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' | sort \
    | while IFS= read -r name; do echo "${pins[$name]:-$name}"; done > "$PACKAGES_FILE"

echo "✅ Global NPM packages ready"
