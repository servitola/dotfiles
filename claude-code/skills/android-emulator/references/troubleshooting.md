# Emulator slow / ANR — diagnostic checklist

Work top-down; each step has a command and an expected result. Symptoms this
fixes: "System UI isn't responding", "Pixel Launcher isn't responding", guest
loadavg 20–40, ping rtt in quadrillions of ms, apps stuck on "connecting".

## 1. HVF acceleration

```bash
~/Library/Android/sdk/emulator/emulator -accel-check
```
Expect `Hypervisor.Framework` and exit 0. If not — the emulator runs in pure
TCG emulation and nothing else matters until this is fixed (reinstall the
`emulator` package via sdkmanager).

## 2. Stuck processes from previous runs

```bash
ps aux | grep -E 'qemu-system|crashpad_handler' | grep -v grep
pkill -f 'sdk/emulator/crashpad_handler'   # orphans are safe to kill
```
A leftover `qemu-system-aarch64` holds RAM and the AVD lock; orphaned
`crashpad_handler`s indicate earlier dirty exits.

## 3. GPU mode actually in effect (main ANR cause)

`config.ini` says what you asked for; `hardware-qemu.ini` says what you got:

```bash
grep gpu ~/.android/avd/<name>.avd/hardware-qemu.ini
grep -E 'vulkan_mode_selected|gles_mode_selected' ~/.android/avd/<name>.avd/launch.log
```
`lavapipe` or `swiftshader` anywhere = rendering on CPU → guest CPU
starvation → ANR storm. Fix: `hw.gpu.mode=host` in config.ini and launch
with `-gpu host` (make-avd does both). `auto` is untrustworthy: on macOS 26 /
emulator 36.5 it silently picked lavapipe.

## 4. Guest health while running

```bash
SER=emulator-5554   # adb devices; use `adb -s $SER emu avd name` to map serial→AVD
adb -s $SER shell cat /proc/loadavg      # 1-min load < hw.cpu.ncore = healthy
adb -s $SER shell head -3 /proc/meminfo  # MemAvailable > ~1 GB = healthy
adb -s $SER shell "toybox nc -w 5 8.8.8.8 443 </dev/null && echo TCP-OK"
adb -s $SER shell "toybox nc -w 5 google.com 443 </dev/null && echo DNS-OK"
adb -s $SER logcat -d -b events | grep -c am_anr   # 0 = no ANRs
adb -s $SER shell "date +%s; sleep 3; date +%s"    # must advance ~3s
```
Judge network by TCP+DNS, not ping: ICMP through the emulator NAT (slirp) is
unreliable by design (packet loss, duplicates, rtt 0.000 are artifacts).
Absurd ping rtt (10^15 ms) = guest clock skew, almost always from a quickboot
snapshot restore → use cold boot (`-no-snapshot`, make-avd default). A live
TCP feed that hangs on "connecting" after resume is the same clock problem.
A guest where CPU is idle but SystemUI ANRs and `screencap` hangs = stalled
host-GPU pipeline → update the emulator (macOS 26 needs emulator ≥ 36.6).

## 5. Background QoS clamp (guest starves while host is idle)

Signature: guest loadavg 20–40 and ANRs, but `ps -o pri,%cpu -p $(pgrep -f
qemu-system)` on the host shows PRI 4 and qemu stuck near 45–85% CPU total.
Darwin background QoS (inherited from a script/agent/cron shell, NI 5 / PRI 4)
pins every vCPU to the 2 efficiency cores. `taskpolicy -B -p <pid>` cannot
un-clamp a live process — relaunch instead. make-avd launches through
`launchctl submit`, which always gets normal QoS (PRI ≥ 20) and prints a
warning if the spawned emulator is still clamped.

## 6. Host background load

vCPUs compete with everything else on the P-cores:

```bash
/usr/bin/top -l 2 -n 8 -o cpu -stats command,cpu | tail -8
```
Heavyweights on this machine: Rider/ReSharper indexing, eqMac+coreaudiod,
Telegram, Zap, WindowServer. If the top consumers sum to several cores,
either close them or lower `--cores` so host+guest fit in 8 P-cores.

## 7. RAM / heap inside the AVD

```bash
grep -E 'ramSize|heapSize' ~/.android/avd/<name>.avd/config.ini
```
Play Store images need 4096 MB (`hw.ramSize`); 2048 causes kswapd churn and
LMK killing SystemUI. `vm.heapSize=512` prevents WebView GC storms. Changing
`disk.dataPartition.size` on an existing AVD requires `-wipe-data` or
`make-avd <api> --recreate` to take effect.

## 8. Outdated emulator / system image

```bash
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --list 2>/dev/null \
  | sed -n '/Available Updates/,$p'
yes | sdkmanager emulator "system-images;android-36;google_apis_playstore;arm64-v8a"
```
API 36 images matured over revisions; keep the emulator and the newest API's
image current. `make-avd doctor` shows pending updates.

## 9. Still broken?

- Wipe and recreate: `make-avd <api> --name <name> --recreate`.
- Try `--gpu swiftshader_indirect` only as a last-resort correctness test
  (it is the slow CPU path — never a performance fix).
- Check `~/.android/avd/<name>.avd/launch.log` for `ERROR`/`FATAL` lines.
