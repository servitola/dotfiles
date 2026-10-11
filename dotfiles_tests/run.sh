#!/bin/zsh
# A new user's Mac, from scratch, in a throwaway tart VM: make, then checks, hotkeys and up.
#   dotfiles_tests/run.sh [--keep] [stage ...]
setopt err_exit no_unset pipe_fail
source "$HOME/projects/dotfiles/constants/load.zsh"
here=${0:a:h}
source "$here/vm.sh"

all_stages=(make remake check doctor links shell hotkeys apps up up2)
typeset -A command=(
    make    "cd ~/projects/dotfiles && HOMEBREW_CACHE='$CACHE_GUEST' make"
    remake  'zsh ~/projects/dotfiles/dotfiles_tests/checks.sh remake'
    check   'zsh ~/projects/dotfiles/install/check.sh'
    doctor  'zsh -lc "brew doctor"'
    links   'zsh ~/projects/dotfiles/dotfiles_tests/checks.sh links'
    shell   'zsh ~/projects/dotfiles/dotfiles_tests/checks.sh shell'
    hotkeys 'zsh ~/projects/dotfiles/dotfiles_tests/hotkeys.sh live'
    apps    'zsh ~/projects/dotfiles/dotfiles_tests/hotkeys.sh apps'
    up      'zsh -ic up'
    up2     'zsh -ic up'
)
typeset -A minutes=(make 240 remake 30 check 5 doctor 5 links 5 shell 2 hotkeys 2 apps 20 up 60 up2 60)

keep=0 stages=()
for arg; do
    case $arg in
        --keep) keep=1 ;;
        ${(~j:|:)all_stages}) stages+=$arg ;;
        *) print -u2 "usage: ${0:t} [--keep] [${(j:|:)all_stages} ...]"; exit 2 ;;
    esac
done
(( $#stages )) || stages=($all_stages)

# run_stage <name>: true when it passed within its time limit.
run_stage() {
    local started=$SECONDS running watchdog
    print "━━ $1"
    $guest_ssh "admin@$ip" "${command[$1]}" </dev/null > >(tee "$logs/$1.log") 2>&1 &
    running=$!
    ( sleep $(( minutes[$1] * 60 )); print "━━ $1 timed out"; kill $running ) 2>/dev/null &
    watchdog=$!
    local result=FAILED
    wait $running && result=passed
    kill $watchdog 2>/dev/null || true
    print "━━ $1 $result ($(( SECONDS - started ))s)"
    [[ $result == passed ]]
}

start_vm
trap stop_vm EXIT
for repository in $HOME/projects/dotfiles $DIR_SKILLS $DIR_CRON; do
    push_repository $repository
done
guest 'zsh -s' < "$here/fresh_mac.sh"
print "testing $(git -C "$HOME/projects/dotfiles" log --oneline -1)"

failed=()
for stage in $stages; do
    run_stage $stage && continue
    failed+=$stage
    [[ $stage != make ]] || break
done

print "\nlogs: $logs"
(( ! $#failed )) || { print "failed: $failed"; exit 1; }
print "all passed: $stages"
