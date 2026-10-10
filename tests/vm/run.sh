#!/bin/zsh
# Fresh-Mac integration test: a throwaway clone of a clean macOS VM on
# $TART_HOST gets this repo's HEAD, then runs `make`, install/check.sh and `up`.
#   tests/vm/run.sh [--keep] [make|check|doctor|up ...]     default: all four
setopt err_exit no_unset pipe_fail
source "$HOME/projects/dotfiles/constants/load.zsh"

IMAGE=ghcr.io/cirruslabs/macos-tahoe-base:latest
BASE=dotfiles-base
# Every run installs the whole brewfile (~30 GB); downloads land on the host
# and are reused, so only the first run pays for them.
CACHE_HOST='$HOME/.cache/tart-homebrew'
CACHE_GUEST='/Volumes/My Shared Files/homebrew'
DISK_GB=100
DOTFILES=$HOME/projects/dotfiles

keep=0 stages=()
for arg; do
    case $arg in
        --keep) keep=1 ;;
        make|check|doctor|up) stages+=$arg ;;
        *) print -u2 "usage: ${0:t} [--keep] [make|check|doctor|up ...]"; exit 2 ;;
    esac
done
(( $#stages )) || stages=(make check doctor up)

host() { ssh "$TART_HOST" "export PATH=/opt/homebrew/bin:\$PATH; $1"; }

# The VM sits on the host's private NAT, so every hop goes through the host.
guest_ssh=(ssh -J "$TART_HOST" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
guest() { "${guest_ssh[@]}" "admin@$ip" "$1"; }

boot() {
    host "mkdir -p $CACHE_HOST && nohup tart run --no-graphics --dir homebrew:$CACHE_HOST $1 >/tmp/$1.log 2>&1 </dev/null &"
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
# M1/M2 have no nested virtualization, so no Docker daemon can run in the VM.
guest "sed -i '' 's/^DOCKER=yes\$/DOCKER=no/' ~/projects/dotfiles/constants.env && grep -qx DOCKER=no ~/projects/dotfiles/constants.env"
# The image's own Metal probe; brew doctor would flag it as an unbrewed dylib
# on every run, and the doctor stage is there to catch what make leaves behind.
guest "sudo rm /usr/local/lib/TartMetalCapabilities.dylib"
print "testing $(git -C "$DOTFILES" log --oneline -1)"

typeset -A command=(
    # Only make reads the shared cache: up starts with rm -rf "$(brew --cache)".
    make  "cd ~/projects/dotfiles && HOMEBREW_CACHE='$CACHE_GUEST' make"
    check 'zsh ~/projects/dotfiles/install/check.sh'
    doctor 'zsh -lc "brew doctor"'
    up    'zsh -ic up'
)
# A step waiting on a dialog nobody sees hangs forever (run 6 sat 4.5 h on
# Gatekeeper's prompt), so each stage has a ceiling.
typeset -A limit=(make 14400 check 300 doctor 300 up 3600)
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
