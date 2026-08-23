#!/usr/bin/env python3
"""Render a Gruvbox heatmap of the InputLogger capture: keys, modifiers, hours.

Usage: python3 hammerspoon/tools/input_heatmap.py [--days N] [-o out.svg]

Key geometry is imported from docs/keyboard/layout.py so the heatmap lines up
with the generated shortcut diagrams. Caps Lock never reaches the tap (Karabiner
eats it), so its cell counts hyper holds recovered from right-modifier bursts.
"""
import argparse, bisect, collections, datetime, glob, json, os, sys

HOME = os.path.expanduser("~")
DOT = f"{HOME}/projects/dotfiles"
DATA = f"{HOME}/Library/Application Support/Hammerspoon/InputLogger"
sys.path.insert(0, f"{DOT}/docs/keyboard")
from layout import ROWS                                          # noqa: E402

U, H, G = 54, 48, 4
BG, KEY0, EDGE, FG, DIM = "#1d2021", "#32302f", "#504945", "#ebdbb2", "#928374"
RAMP = ["#3c3836", "#458588", "#689d6a", "#98971a", "#d79921", "#fe8019", "#fb4934"]

KEYCODE = {
    "tilde": 50, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26,
    "8": 28, "9": 25, "0": 29, "minus": 27, "equal": 24, "backspace": 51,
    "tab": 48, "q": 12, "w": 13, "e": 14, "r": 15, "t": 17, "y": 16, "u": 32,
    "i": 34, "o": 31, "p": 35, "bracketleft": 33, "bracketright": 30, "backslash": 42,
    "a": 0, "s": 1, "d": 2, "f": 3, "g": 5, "h": 4, "j": 38, "k": 40, "l": 37,
    "semicolon": 41, "apostrophe": 39, "return": 36,
    "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "n": 45, "m": 46,
    "comma": 43, "period": 47, "slash": 44, "space": 49,
    "left": 123, "right": 124,
}
MULTI = {"updown": (125, 126)}
MOD_CELL = {"shift": 56, "shift_r": 60, "cmd": 55, "cmd_r": 54,
            "opt": 58, "opt_r": 61, "ctrl": 59}
RIGHT_CODES = {54, 60, 61, 62}

# karabiner key_code -> macOS virtual keycode, for translating marker labels
KARABINER_VK = dict(KEYCODE, spacebar=49, delete_or_backspace=51, return_or_enter=36,
                    open_bracket=33, close_bracket=30, semicolon=41, quote=39,
                    comma=43, period=47, slash=44, hyphen=27, equal_sign=24,
                    grave_accent_and_tilde=50, left_arrow=123, right_arrow=124,
                    up_arrow=126, down_arrow=125, escape=53, caps_lock=57,
                    page_up=116, page_down=121, delete_forward=117)


def heat(t):
    if t <= 0:
        return KEY0
    x = t * (len(RAMP) - 1)
    i = min(int(x), len(RAMP) - 2)
    f = x - i
    a, b = RAMP[i], RAMP[i + 1]
    return "#" + "".join(f"{round(int(a[1+2*k:3+2*k],16)*(1-f)+int(b[1+2*k:3+2*k],16)*f):02x}"
                         for k in range(3))


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=float, default=0)
    ap.add_argument("-o", "--out", default="/tmp/input-heatmap.svg")
    args = ap.parse_args()

    rows = []
    for path in sorted(glob.glob(f"{DATA}/combos-*.jsonl")):
        with open(path) as fh:
            for line in fh:
                line = line.strip()
                if line:
                    rows.append(json.loads(line))
    rows.sort(key=lambda r: r["ts"])
    if args.days:
        rows = [r for r in rows if r["ts"] >= rows[-1]["ts"] - args.days * 86_400_000]

    sess, cur = [], None
    for r in rows:
        if r.get("type") == "mod" and r.get("side") == "right" and r["code"] in RIGHT_CODES:
            if cur and r["ts"] - cur[1] < 200:
                cur[1] = r["ts"]
            else:
                if cur:
                    sess.append(cur)
                cur = [r["ts"], r["ts"]]
    if cur:
        sess.append(cur)
    holds = len(sess)
    starts = [a - 30 for a, _ in sess]
    ends = [b + 30 for _, b in sess]

    def in_hyper(ts):
        i = bisect.bisect_right(starts, ts) - 1
        return i >= 0 and ts <= ends[i]

    # markers name the key the finger actually hit; without them the map draws ⇪a
    # on the arrow cluster and ⇪⇥ on Enter, because that is all eventtap ever sees
    markers = []
    for path in sorted(glob.glob(f"{DATA}/physical-*.jsonl")):
        with open(path) as fh:
            for line in fh:
                line = line.strip()
                if line:
                    markers.append(json.loads(line))
    markers = [m for m in markers if rows[0]["ts"] <= m["ts"] <= rows[-1]["ts"]]
    markers.sort(key=lambda m: m["ts"])

    down_ts, down_code, consumed = [], [], set()
    for i, r in enumerate(rows):
        if r.get("type") == "key" and r["state"] == "down" and not r.get("autorepeat"):
            down_ts.append(r["ts"])
            down_code.append((i, r["code"]))
    for m in markers:
        out = m["sent"].split(",")[0].split("+")[-1]
        vk = KARABINER_VK.get(out)
        if vk is None:
            continue                      # consumer keys never reach eventtap anyway
        lo = bisect.bisect_left(down_ts, m["ts"] - 150)
        for j in range(lo, min(lo + 12, len(down_ts))):
            if down_ts[j] > m["ts"] + 150:
                break
            idx, code = down_code[j]
            if code == vk and idx not in consumed:
                consumed.add(idx)
                break

    keys = collections.Counter()
    for i, r in enumerate(rows):
        if r.get("type") == "key" and r["state"] == "down" and not r.get("autorepeat"):
            if i not in consumed:
                keys[r["code"]] += 1
        elif r.get("type") == "mod" and r["state"] == "down":
            # a right-side modifier is Karabiner replaying ⇪, not a finger on the key
            if r["code"] in RIGHT_CODES and in_hyper(r["ts"]):
                continue
            keys[r["code"]] += 1

    offmap = collections.Counter()
    for m in markers:
        vk = KARABINER_VK.get(m["chord"].split("+")[-1])
        if vk is None:
            offmap[m["chord"]] += 1
        else:
            keys[vk] += 1

    hours = collections.Counter()
    for r in rows:
        if r.get("type") in ("key", "mouse") and r["state"] == "down":
            d = datetime.datetime.fromtimestamp(r["ts"] / 1000)
            hours[(d.strftime("%d.%m"), d.hour)] += 1

    def count(kid):
        if kid == "capslock":
            return sum(1 for m in markers if m["chord"].startswith("hyper")) or holds
        if kid in MULTI:
            return sum(keys.get(c, 0) for c in MULTI[kid])
        if kid in MOD_CELL:
            return keys.get(MOD_CELL[kid], 0)
        return keys.get(KEYCODE.get(kid, -1), 0)

    days = sorted({d for d, _ in hours}, key=lambda s: (s[3:], s[:2]))
    peak = max(count(kid) for row in ROWS for _, _, kid in row)
    width = int(max(sum(wu * U + (wu - 1) * G + G for _, wu, _ in row) for row in ROWS)) + 40
    kb_h = len(ROWS) * (H + G)
    height = 110 + kb_h + len(days) * 18 + 80

    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
         f'viewBox="0 0 {width} {height}" font-family="SF Pro Text, Helvetica, Arial, sans-serif">',
         f'<rect width="{width}" height="{height}" fill="{BG}"/>']

    t0 = datetime.datetime.fromtimestamp(rows[0]["ts"] / 1000)
    t1 = datetime.datetime.fromtimestamp(rows[-1]["ts"] / 1000)
    total = sum(v for k, v in keys.items() if k not in RIGHT_CODES)
    o.append(f'<text x="20" y="38" fill="{FG}" font-size="22" font-weight="600">'
             f'Тепловая карта клавиатуры</text>')
    o.append(f'<text x="20" y="60" fill="{DIM}" font-size="13">'
             f'{t0:%d.%m %H:%M} — {t1:%d.%m %H:%M} · {total} нажатий · '
             f'пик {peak} · чорды отнесены на физически нажатую клавишу</text>')

    y = 84
    for row in ROWS:
        x = 20
        for label, wu, kid in row:
            w = wu * U + (wu - 1) * G
            n = count(kid)
            t = (n / peak) ** 0.42 if peak and n else 0
            o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{H}" rx="6" '
                     f'fill="{heat(t)}" stroke="{EDGE}" stroke-width="1"/>')
            tone = FG if t < 0.62 else "#1d2021"
            o.append(f'<text x="{x+w/2}" y="{y+20}" fill="{tone}" font-size="14" '
                     f'text-anchor="middle">{esc(label)}</text>')
            if n:
                o.append(f'<text x="{x+w/2}" y="{y+37}" fill="{tone}" font-size="11" '
                         f'opacity="0.85" text-anchor="middle">{n}</text>')
            x += w + G
        y += H + G

    y += 34
    o.append(f'<text x="20" y="{y-12}" fill="{FG}" font-size="15" font-weight="600">'
             f'Активность по дням и часам</text>')
    peak_h = max(hours.values()) if hours else 1
    cw = (width - 96) / 24
    for hh in range(0, 24, 2):
        o.append(f'<text x="{62+cw*(hh+0.5)}" y="{y+2}" fill="{DIM}" font-size="10" '
                 f'text-anchor="middle">{hh}</text>')
    for di, dn in enumerate(days):
        yy = y + 10 + di * 18
        o.append(f'<text x="52" y="{yy+12}" fill="{DIM}" font-size="11" '
                 f'text-anchor="end">{dn}</text>')
        for hh in range(24):
            n = hours.get((dn, hh), 0)
            t = (n / peak_h) ** 0.42 if n else 0
            o.append(f'<rect x="{62+cw*hh}" y="{yy}" width="{cw-2}" height="16" rx="2" '
                     f'fill="{heat(t)}"/>')

    o.append("</svg>")
    with open(args.out, "w") as fh:
        fh.write("\n".join(o))
    off = ", ".join(f"{k}={v}" for k, v in offmap.most_common(6))
    print(f"{args.out}  ({total} нажатий, пик {peak}, маркеров {len(markers)}, "
          f"перенесено на физическую клавишу {len(consumed)})")
    if off:
        print(f"  вне 60% раскладки (рисовать негде): {off}")


if __name__ == "__main__":
    main()
