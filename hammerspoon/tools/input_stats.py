#!/usr/bin/env python3
"""Report on the InputLogger capture.

Usage: python3 hammerspoon/tools/input_stats.py [--days N]

Three layers, joined here:
  physical-*.jsonl  what the finger pressed  (Karabiner markers, ground truth)
  combos-*.jsonl    what macOS received      (hs.eventtap, below Karabiner)
  combos app field  where it happened

Chords used to be reconstructed from the burst of right-side modifiers Karabiner
emits around a Caps hold. Measured against the markers, that burst accompanies
only 21% of chords, so everything it produced was a severe undercount; it is
gone. What the markers cannot see are chords with no Karabiner rule at all
(⇪t, ⇪f, ⇪g, ⇪h, ⇪b pass straight through) — those still come from combos, where
they arrive carrying all four modifiers.
"""
import argparse, bisect, collections, datetime, glob, json, os, re

HOME = os.path.expanduser("~")
DATA = f"{HOME}/Library/Application Support/Hammerspoon/InputLogger"
LAYOUT = f"{HOME}/projects/dotfiles/hammerspoon/Spoons/HotKeys.spoon/layout/60%"

VK = {0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
      10: "§", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1",
      19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-",
      28: "8", 29: "0", 30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p",
      36: "return", 37: "l", 38: "j", 39: "'", 40: "k", 41: ";", 42: "\\", 43: ",",
      44: "/", 45: "n", 46: "m", 47: ".", 48: "tab", 49: "space", 50: "`", 51: "⌫",
      53: "esc", 64: "F17", 79: "F18", 80: "F19", 82: "num0", 83: "num1", 84: "num2",
      85: "num3", 86: "num4", 87: "num5", 88: "num6", 89: "num7", 90: "F20",
      91: "num8", 92: "num9", 105: "F13", 106: "F16", 107: "F14", 109: "F10",
      113: "F15", 115: "home", 116: "pageup", 117: "delfwd", 119: "end",
      121: "pagedown", 122: "F1", 120: "F2", 123: "←", 124: "→", 125: "↓", 126: "↑"}

PRETTY_MOD = {"hyper": "⇪", "lshift": "⇧", "shift": "⇧", "lctrl": "⌃",
              "lopt": "⌥", "lcmd": "⌘", "fn": "fn"}
PRETTY_KEY = {"spacebar": "␣", "delete_or_backspace": "⌫", "return_or_enter": "↩",
              "tab": "⇥", "escape": "⎋", "slash": "/", "quote": "'", "comma": ",",
              "period": ".", "semicolon": ";", "hyphen": "-", "equal_sign": "=",
              "open_bracket": "[", "close_bracket": "]", "grave_accent_and_tilde": "`",
              "non_us_backslash": "§", "left_arrow": "←", "right_arrow": "→",
              "up_arrow": "↑", "down_arrow": "↓", "caps_lock": "⇪", "backslash": "\\",
              "page_up": "pageup", "page_down": "pagedown", "delete_forward": "delfwd"}
MEANING = {"←": "курсор влево", "→": "вправо", "↑": "вверх", "↓": "вниз",
           "pageup": "страница вверх", "pagedown": "страница вниз",
           "delfwd": "удалить вперёд", "↩": "Enter", "⌫": "стереть",
           "volume_increment": "громкость +", "volume_decrement": "громкость −",
           "display_brightness_increment": "яркость +",
           "display_brightness_decrement": "яркость −",
           "play_or_pause": "play/pause", "mute": "звук off"}


def pretty(token):
    parts = token.split("+")
    key = parts[-1]
    key = PRETTY_KEY.get(key, key.upper() if re.fullmatch(r"f\d+", key) else key)
    return "".join(PRETTY_MOD.get(m, m) for m in parts[:-1]) + key


def load(pattern, days, anchor=None):
    rows = []
    for path in sorted(glob.glob(f"{DATA}/{pattern}")):
        with open(path) as fh:
            for line in fh:
                line = line.strip()
                if line:
                    rows.append(json.loads(line))
    rows.sort(key=lambda r: r["ts"])
    if days and rows:
        cutoff = (anchor or rows[-1]["ts"]) - days * 86_400_000
        rows = [r for r in rows if r["ts"] >= cutoff]
    return rows


def bound_chords():
    out = {}
    for path in sorted(glob.glob(f"{LAYOUT}/*.lua")):
        for line in open(path):
            m = re.search(r'chord\s*=\s*"([^"]+)"', line)
            if not m:
                continue
            act = re.search(r'(app|fn|sendKey)\s*=\s*"([^"]+)"', line)
            out[m.group(1)] = f"{act.group(1)}:{act.group(2)}" if act else "?"
    return out


def hs_chord(key, flags):
    out, rest = "", set(flags)
    if {"cmd", "alt", "ctrl", "shift"} <= rest:
        out, rest = "⇪", rest - {"cmd", "alt", "ctrl", "shift"}
    for f, s in (("shift", "⇧"), ("ctrl", "⌃"), ("alt", "⌥"), ("cmd", "⌘")):
        if f in rest:
            out += s
    return out + {"tab": "⇥", "esc": "⎋", "space": "␣"}.get(key, key)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=float, default=0)
    args = ap.parse_args()

    combos = load("combos-*.jsonl", args.days)
    phys = load("physical-*.jsonl", args.days, anchor=combos[-1]["ts"] if combos else None)

    span = (combos[-1]["ts"] - combos[0]["ts"]) / 3.6e6
    downs = [r for r in combos if r.get("type") == "key" and r["state"] == "down"
             and not r.get("autorepeat")]
    clicks = [r for r in combos if r.get("type") == "mouse" and r["state"] == "down"]
    t0 = datetime.datetime.fromtimestamp(combos[0]["ts"] / 1000)
    t1 = datetime.datetime.fromtimestamp(combos[-1]["ts"] / 1000)
    print(f"окно {t0:%d.%m %H:%M} → {t1:%d.%m %H:%M}  ({span:.1f} ч)")
    print(f"нажатий {len(downs)} ({len(downs)/span:.0f}/ч) | кликов {len(clicks)} "
          f"({len(clicks)/span:.0f}/ч)")

    if not phys:
        print("\nфизического лога нет — соберите karabiner/build.sh, чорды не восстановимы")
        return
    p0 = datetime.datetime.fromtimestamp(phys[0]["ts"] / 1000)
    print(f"маркеров Karabiner {len(phys)} (пишутся с {p0:%d.%m %H:%M})")

    app_ts = [r["ts"] for r in combos]
    app_at = [r.get("app") for r in combos]

    def app_for(ts):
        i = bisect.bisect_right(app_ts, ts) - 1
        return app_at[i] if i >= 0 else None

    print("\n== чорды: что нажато физически ==")
    chords = collections.Counter()
    chord_app = collections.defaultdict(collections.Counter)
    for r in phys:
        c = pretty(r["chord"])
        chords[(c, pretty(r["sent"]) if "+" not in r["sent"] else pretty(r["sent"]))] += 1
        chord_app[c][app_for(r["ts"])] += 1
    # chords Karabiner never touches arrive intact, all four modifiers attached
    passthrough = collections.Counter()
    for r in downs:
        fl = {f for f in (r.get("modifiers") or []) if f in ("cmd", "alt", "ctrl", "shift")}
        if fl == {"cmd", "alt", "ctrl", "shift"}:
            passthrough[("⇪" + VK.get(r["code"], f"vk{r['code']}"), "—")] += 1
    merged = chords + passthrough
    for (c, sent), n in merged.most_common(30):
        top = chord_app[c].most_common(1)
        where = f"  ·  {top[0][0].split('.')[-1]}" if top and top[0][0] else ""
        note = f"  → {MEANING.get(sent, sent)}" if sent != "—" else "  (без правила)"
        print(f"  {n:5d}  {c:10s}{note}{where}")

    print("\n== привязанные чорды HotKeys, не сработавшие ни разу ==")
    seen = {c for c, _ in merged}
    for r in phys:
        seen.add(pretty(r["sent"]))
    for r in downs:
        seen.add(hs_chord(VK.get(r["code"], f"vk{r['code']}"),
                          {f for f in (r.get("modifiers") or [])
                           if f in ("cmd", "shift", "alt", "ctrl")}))
    bound = bound_chords()
    dead = sorted(f"{c:12s} {a}" for c, a in bound.items() if c not in seen)
    print(f"мёртвых {len(dead)} из {len(bound)}")
    for line in dead:
        print(f"  {line}")

    print("\n== навигация по смыслу ==")
    nav = collections.Counter()
    for r in downs:
        key = VK.get(r["code"])
        if key not in ("←", "→", "↑", "↓", "pageup", "pagedown", "home", "end", "delfwd"):
            continue
        fl = sorted(f for f in (r.get("modifiers") or [])
                    if f in ("cmd", "shift", "alt", "ctrl"))
        nav[("+".join(fl) + " " if fl else "") + key] += 1
    hyper_nav = sum(n for (c, s), n in chords.items()
                    if s in ("←", "→", "↑", "↓", "pageup", "pagedown"))
    for k, v in nav.most_common(10):
        print(f"  {v:5d}  {k}")
    total_arrows = sum(v for k, v in nav.items() if k.endswith(("←", "→", "↑", "↓")))
    if total_arrows:
        print(f"  из них через ⇪-слой: {hyper_nav} ({100*hyper_nav/total_arrows:.0f}%)")

    print("\n== доля нажатий, тут же стёртых Backspace ==")
    def bare(r):
        return not [f for f in (r.get("modifiers") or [])
                    if f in ("cmd", "shift", "alt", "ctrl")]

    typed = collections.Counter(r["code"] for r in downs if bare(r))
    deleted = collections.Counter()
    prev = None
    for r in downs:
        if r["code"] == 51 and prev is not None and prev[0] != 51 and prev[1]:
            deleted[prev[0]] += 1
        prev = (r["code"], bare(r))
    rates = sorted(((100 * deleted.get(c, 0) / n, VK.get(c, c), deleted.get(c, 0), n)
                    for c, n in typed.items() if n >= 150 and c != 51), reverse=True)
    for rate, name, d, n in rates[:8]:
        print(f"  {str(name):8s} {d:5d} из {n:6d}  {rate:5.1f}%")

    print("\n== по приложениям ==")
    kb = collections.Counter(r.get("app") for r in downs)
    ms = collections.Counter(r.get("app") for r in clicks)
    for app, _ in (kb + ms).most_common(12):
        k, m = kb.get(app, 0), ms.get(app, 0)
        print(f"  {(app or '?').split('.')[-1]:24s} клавиш {k:7d}  кликов {m:6d}"
              f"  {k/m:6.1f}" if m else
              f"  {(app or '?').split('.')[-1]:24s} клавиш {k:7d}  кликов {m:6d}")


if __name__ == "__main__":
    main()
