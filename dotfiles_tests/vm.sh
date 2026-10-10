# Tart plumbing for run.sh: the base image, one throwaway clone, ssh into it.
# The VM sits on $TART_HOST's private network, so every hop goes through the host.

IMAGE=ghcr.io/cirruslabs/macos-tahoe-base:latest
BASE=dotfiles-base
DISK_GB=100
CACHE_HOST='$HOME/.cache/tart-homebrew'
CACHE_GUEST='/Volumes/My Shared Files/homebrew'

ssh_options=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
guest_ssh=(ssh -J "$TART_HOST" $ssh_options)

host() { ssh "$TART_HOST" "export PATH=/opt/homebrew/bin:\$PATH; $1"; }
guest() { $guest_ssh "admin@$ip" "$@"; }

boot() {
    # Homebrew parks files it moves aside in $HOMEBREW_CACHE/Backup; leftovers
    # from one run broke the next with "File exists".
    host "mkdir -p $CACHE_HOST && rm -rf $CACHE_HOST/Backup
          nohup tart run --no-graphics --dir homebrew:$CACHE_HOST $1 >/tmp/$1.log 2>&1 </dev/null &"
    ip=$(host "tart ip $1 --wait 180")
    host "until nc -z -G 2 $ip 22 2>/dev/null; do sleep 2; done"
}

bake_base() {
    print "baking $BASE from $IMAGE"
    host "tart clone $IMAGE $BASE && tart set $BASE --disk-size $DISK_GB"
    boot $BASE
    authorize_keys
    # The first resize after repairDisk fails with APFS error 49189; a second one works.
    guest "yes | sudo diskutil repairDisk disk0 >/dev/null
           sudo diskutil apfs resizeContainer disk0s2 0 || sudo diskutil apfs resizeContainer disk0s2 0"
    host "tart stop $BASE"
}

# The image accepts only the password admin/admin until our keys are in.
authorize_keys() {
    local keys=$( { cat ~/.ssh/id_ed25519.pub; host 'cat ~/.ssh/id_ed25519.pub'; } | base64 )
    host "expect -f -" <<EOF
set timeout 30
spawn ssh $ssh_options -o PubkeyAuthentication=no admin@$ip "mkdir -p ~/.ssh && echo $keys | base64 -d >> ~/.ssh/authorized_keys"
expect "assword:" { send "admin\r" }
expect eof
EOF
}

start_vm() {
    host "tart list --quiet" | grep -qx $BASE || bake_base
    vm=dotfiles-test-$(date +%Y%m%d-%H%M%S)
    logs=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/vm-test/$vm
    mkdir -p "$logs"
    host "tart clone $BASE $vm"
    boot $vm
    print "$vm at $ip, logs in $logs"
}

stop_vm() {
    if (( keep )); then
        print "kept: $guest_ssh admin@$ip   (drop: ssh $TART_HOST tart delete $vm)"
    else
        host "tart stop --timeout 30 $vm; tart delete $vm" || true
    fi
}

# push_repository <dir>: its committed HEAD, cloned to the same path in the VM.
push_repository() {
    local name=${1:t} bundle=$logs/${1:t}.bundle
    git -C "$1" bundle create "$bundle" HEAD "$(git -C "$1" symbolic-ref --short HEAD)" 2>/dev/null
    scp -q -o ProxyJump="$TART_HOST" $ssh_options "$bundle" "admin@$ip:/tmp/$name.bundle"
    guest "mkdir -p ~/projects && git clone -q /tmp/$name.bundle ~/projects/$name"
}
