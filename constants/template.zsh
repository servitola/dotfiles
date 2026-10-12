#!/bin/zsh
# render <config> — expand the ${CONSTANT}s of a config whose own tool expands
# nothing, into the state dir the symlinks point at. The repo file is the
# template; every $ in it is expanded, so a literal one needs \$.
set -euo pipefail
source ~/projects/dotfiles/constants/load.zsh

GENERATED=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/generated
mkdir -p $GENERATED

render() {
    local template=$(<$1) line
    # NONE: this Mac has no such thing. The configs read an empty value as "off"
    # (git's `proxy =` is no proxy, NuGet skips an empty http_proxy).
    for line in ${(M)${(f)"$(<~/projects/dotfiles/constants.env)"}:#[A-Z]*=NONE}; do
        local ${line%%=*}=
    done
    print -r -- "${(e)template}" > $GENERATED/${1:t}
    print "  $GENERATED/${1:t}"
}
