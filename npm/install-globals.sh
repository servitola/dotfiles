#!/bin/zsh
# Brings the global npm packages in line with global-packages.txt, then writes the list back
# from what is installed, so `npm i -g` / `npm rm -g` done by hand end up in the file too.
# Run by install step 12 and sourced by `up`.

npm_globals() {
    local list=${NPM_GLOBALS_LIST:-$HOME/projects/dotfiles/npm/global-packages.txt}
    # npmrc refuses releases younger than min-release-age days, so "newest" means newest of those.
    local age=$(npm config get min-release-age)
    [[ $age == <-> ]] || age=0

    local -A pinned=() failed=()
    local spec name version installed wanted changed=0

    while IFS= read -r spec || [[ -n $spec ]]; do
        [[ -z $spec || $spec == \#* ]] && continue
        if [[ $spec == ?*@* ]]; then
            name=${spec%@*} version=${spec##*@}
            pinned[$name]=$spec
        else
            name=$spec version=
        fi

        installed=$(npm list -g "$name" --depth=0 --json 2>/dev/null | jq -r ".dependencies[\"$name\"].version // empty")
        if [[ -n $version ]]; then
            wanted=$version
        else
            wanted=$(npm view "$name" time --json 2>/dev/null | jq -r --argjson days "$age" '
                to_entries
                | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
                | map(select((.value | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) <= now - $days * 86400))
                | .[].key' | sort -V | tail -1)
        fi

        if [[ -z $wanted ]]; then
            print "      ✗ $name: no version on the registry"
            failed[$name]=$spec
            continue
        fi
        [[ $installed == "$wanted" ]] && continue
        # A newer version installed by hand stays: only a pin moves a package back.
        if [[ -z $version && -n $installed && $(print -l "$installed" "$wanted" | sort -V | tail -1) == "$installed" ]]; then
            continue
        fi

        # A quarantine flag left on the old files makes npm fail to replace them.
        xattr -cr "$(npm root -g)/$name" 2>/dev/null
        if npm install -g --silent "$name@$wanted" >/dev/null 2>&1; then
            print "      ✓ $name ${installed:-new} → $wanted"
            changed=$(( changed + 1 ))
        else
            print "      ✗ $name $wanted: npm install failed"
            failed[$name]=$spec
        fi
    done < "$list"

    # Failed entries stay in the file: a network hiccup must not erase them from the list.
    { npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]'; (( ${#failed} )) && print -l ${(k)failed}; } \
        | sort -u | while IFS= read -r name; do
            print -r -- "${pinned[$name]:-${failed[$name]:-$name}}"
        done > "$list"

    (( changed || ${#failed} )) || print "      all $(grep -c . "$list") packages up to date"
}

npm_globals
