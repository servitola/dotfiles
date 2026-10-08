#!/bin/zsh
# Fresh-Mac integration test: a throwaway clone of a clean macOS VM on
# $TART_HOST gets this repo's HEAD, then runs `make`, install/check.sh and `up`.
#   tests/vm/run.sh [--keep] [make|check|up ...]     default: all three
setopt err_exit no_unset pipe_fail
source "$HOME/projects/dotfiles/constants/load.zsh"

IMAGE=ghcr.io/cirruslabs/macos-tahoe-base:latest
BASE=dotfiles-base
DISK_GB=100
DOTFILES=$HOME/projects/dotfiles

keep=0 stages=()
for arg; do
    case $arg in
        --keep) keep=1 ;;
        make|check|up) stages+=$arg ;;
        *) print -u2 "usage: ${0:t} [--keep] [make|check|up ...]"; exit 2 ;;
    esac
done
(( $#stages )) || stages=(make check up)

host() { ssh "$TART_HOST" "export PATH=/opt/homebrew/bin:\$PATH; $1"; }

# The VM sits on the host's private NAT, so every hop goes through the host.
guest_ssh=(ssh -J "$TART_HOST" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
guest() { "${guest_ssh[@]}" "admin@$ip" "$1"; }

boot() {
    host "nohup tart run --no-graphics $1 >/tmp/$1.log 2>&1 </dev/null &"
    ip=$(host "tart ip $1 --wait 180")
    host "until nc -z -G 2 $ip 22 2>/dev/null; do sleep 2; done"
}

# Once per image: the cirruslabs image only takes the password admin/admin and
# ships a disk too small for the full brewfile.
bake_base() {
    print "baking $BASE from $IMAGE"
    host "tart clone $IMAGE $BASE && tart set $BASE --disk-size $DISK_GB"
    boot $BASE
    local keys=$( { cat ~/.ssh/id_ed25519.pub; host 'cat ~/.ssh/id_ed25519.pub'; } | base64 )
    host "expect -f -" <<EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAuthentication=no admin@$ip "mkdir -p ~/.ssh && echo $keys | base64 -d >> ~/.ssh/authorized_keys"
expect "assword:" { send "admin\r" }
expect eof
EOF
    # On 26.6 the first resize right after repairDisk fails with APFS error
    # 49189 and rolls back; the same command again succeeds.
    guest "yes | sudo diskutil repairDisk disk0 >/dev/null
           sudo diskutil apfs resizeContainer disk0s2 0 || sudo diskutil apfs resizeContainer disk0s2 0
           df -H / | tail -1"
    host "tart stop $BASE"
}

host "tart list --quiet" | grep -qx $BASE || bake_base

vm=dotfiles-test-$(date +%Y%m%d-%H%M%S)
logs=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/vm-test/$vm
mkdir -p "$logs"

cleanup() {
    if (( keep )); then
        print "kept: ${guest_ssh[*]} admin@$ip   (drop: ssh $TART_HOST tart delete $vm)"
    else
        host "tart stop --timeout 30 $vm; tart delete $vm" || true
    fi
}
trap cleanup EXIT

host "tart clone $BASE $vm"
boot $vm
print "$vm at $ip, logs in $logs"

bundle=$logs/dotfiles.bundle
git -C "$DOTFILES" bundle create "$bundle" HEAD master 2>/dev/null
scp -q -o ProxyJump="$TART_HOST" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    "$bundle" "admin@$ip:/tmp/dotfiles.bundle"
guest "mkdir -p ~/projects && git clone -q /tmp/dotfiles.bundle ~/projects/dotfiles"
print "testing $(git -C "$DOTFILES" log --oneline -1)"

typeset -A command=(
    make  'cd ~/projects/dotfiles && NO_DOCKER=1 make'
    check 'zsh ~/projects/dotfiles/install/check.sh'
    up    'NO_DOCKER=1 zsh -ic up'
)
# A step waiting on a dialog nobody sees hangs forever (run 6 sat 4.5 h on
# Gatekeeper's prompt), so each stage has a ceiling.
typeset -A limit=(make 3600 check 300 up 3600)
failed=()
for stage in $stages; do
    print "━━ $stage"
    started=$SECONDS
    "${guest_ssh[@]}" "admin@$ip" "${command[$stage]}" </dev/null > >(tee "$logs/$stage.log") 2>&1 &
    running=$!
    ( sleep ${limit[$stage]}; print "━━ $stage timed out after ${limit[$stage]}s"; kill $running ) 2>/dev/null &
    watchdog=$!
    if wait $running; then
        kill $watchdog 2>/dev/null || true
        print "━━ $stage passed ($(( SECONDS - started ))s)"
    else
        kill $watchdog 2>/dev/null || true
        print "━━ $stage FAILED ($(( SECONDS - started ))s)"
        failed+=$stage
        # check and up only report the fallout of a half-done install
        [[ $stage != make ]] || break
    fi
done

print "\nlogs: $logs"
(( ! $#failed )) || { print "failed: $failed"; exit 1; }
print "all passed: $stages"
