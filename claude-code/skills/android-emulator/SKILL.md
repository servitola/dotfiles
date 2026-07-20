---
name: android-emulator
description: |
  Create, launch, and diagnose Android emulators (AVD) on Apple Silicon via the
  make-avd CLI: optimal RAM/CPU/GPU settings for M1 Max, host-GPU rendering,
  cold boot, ANR/CPU-starvation troubleshooting.

  Use when: "создай эмулятор", "сделай AVD", "настрой AVD", "create an emulator", "make an AVD"
---

# Android Emulator on Apple Silicon

Companion skill for the `make-avd` CLI (`~/.local/bin/make-avd`). It creates
AVDs with settings proven and launches them with the right flags.

## Quick start

```bash
command -v make-avd            # verify the CLI is installed
make-avd doctor                # health check: HVF, stuck qemu, host load, versions
make-avd 35                    # create (idempotent) + launch tuned API 35 AVD "api35"
make-avd 36 --name pixel36     # same for API 36 with a custom name
make-avd launch api35          # relaunch an existing AVD with correct flags
make-avd list                  # AVDs with ram/cores/gpu at a glance
```

`make-avd <api>` is idempotent: if the AVD exists it re-enforces the tuned
config instead of failing; `--recreate` rebuilds from scratch. It waits for
`sys.boot_completed`, then prints guest loadavg and a network check.

## Why these defaults (keep them as-is)

| Setting | Value | Reason |
|---|---|---|
| hw.gpu.mode | `host` | `auto` silently resolves to lavapipe/swiftshader (CPU rasterizer) on this host → guest loadavg 20–40, SystemUI/Launcher ANR. `host` = gfxstream/ANGLE on Metal GPU. Guest ANGLE is unstable for API > 35 (emulator's own boot warning). |
| hw.ramSize | 4096 | Play Store image eats ~1.7 GB right after boot; 2048 keeps the guest in permanent memory pressure (kswapd + LMK kill SystemUI). |
| hw.cpu.ncore | 6 | 6 of 8 P-cores for vCPUs; leaves headroom for the host and QEMU's own render/IO threads. 4 was too few for boot storms; 8+ starves QEMU itself. |
| vm.heapSize | 512 | Default 228 MB caps per-app Dalvik heap; WebView-heavy apps GC-storm and ANR. |
| disk.dataPartition.size | 16G | 6G fills with GMS/Play updates; qcow2 grows lazily so 16G costs only what's written. |
| cold boot (`-no-snapshot`) | on | Quickboot snapshot restore skews the guest clock: ping rtt in quadrillions of ms, false ANR watchdogs, dead TCP feeds (live quote streams hang on "connecting"). Cold boot with these settings takes ~18–40 s. |
| `-no-audio` | on | Host CoreAudio runs through eqMac; emulator audio adds stutter and load. |
| on-screen keyboard | forced on | We almost always want the **full on-screen keyboard, like a real phone.** But `hw.keyboard=yes` (host-keyboard passthrough, convenient for typing) also registers a virtual `ALPHAKEY` device, so Android **hides the soft IME** — text fields focus with a cursor but no visible keyboard (very visible inside WebViews / when driving via `adb input`). `make-avd` fixes this by setting `show_ime_with_hard_keyboard=1` right after boot. Persists across reboots. **Must be applied at boot** (before any input connection): setting it mid-session does NOT take effect and needs a device reboot. |
| launch via `launchctl submit` | built-in | A shell with darwin background QoS (scripts, agents, cron) pins all vCPUs to the 2 E-cores: host shows qemu at PRI 4 / ~45% CPU while the guest reports loadavg 30+ and ANR-storms. launchd spawns the emulator at normal QoS (PRI ≥ 20) regardless of caller. |
| emulator ≥ 36.6 | required | 36.5.10 on macOS 26 stalls the host-GPU display pipeline (SystemUI "failed to complete startup" ANRs with an idle CPU, hung `screencap`). |

## API level choice

Both are verified healthy on this machine (2026-07): API 35 cold-boots in
~18 s, API 36 in ~39 s, both with 0 ANRs, guest loadavg < 1 at idle, working
TCP/DNS, ~400 ms app cold starts. API 35 (Android 15) already has the
edge-to-edge + IME insets behavior, so it is a safe default; API 36 needs
emulator ≥ 36.6.11 and image rev ≥ 7 (`google_apis_playstore`;
android-36.1 has no Play Store variant installed). If an API level
misbehaves, run `make-avd doctor` first, then check
[troubleshooting.md](references/troubleshooting.md).

## Emulator slow / ANR again?

Work through the checklist in
[troubleshooting.md](references/troubleshooting.md) — HVF check, host
background load, stuck qemu processes, GPU mode verification inside
hardware-qemu.ini, guest loadavg/clock checks, SDK updates.
