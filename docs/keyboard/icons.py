"""Extract app icons from macOS as base64 PNG for SVG embedding."""
import base64, os, re, subprocess as sp, tempfile


_SLUG_RE = re.compile(r"[^a-z0-9]+")

def icon_slug(name):
    """Stable SVG-id-safe slug for an app name. `IINA`→`iina`, `zoom.us`→`zoom-us`."""
    return _SLUG_RE.sub("-", (name or "").lower()).strip("-") or "unknown"


# Display name → actual bundle filename when they don't match. Add new entries
# here when a layout file references a label that differs from the installed
# `.app` (typically because of forks / open-source variants).
_NAME_OVERRIDES = {
    "Iina": "IINA",
    "XCode": "Xcode",
}
_JXA = ('ObjC.import("AppKit");var ws=$.NSWorkspace.sharedWorkspace,'
    'i=ws.iconForFile("APP");i.setSize({width:SZ,height:SZ});'
    'var r=$.NSBitmapImageRep.imageRepWithData(i.TIFFRepresentation);'
    'r.representationUsingTypeProperties($.NSBitmapImageFileTypePNG,$())'
    '.writeToFileAtomically("OUT",true);')

def _find(name):
    """Locate a real .app bundle for `name`. Iterates mdfind hits and skips
    non-bundle matches (e.g. `/usr/share/terminfo/69/iTerm.app` is a compiled
    terminfo entry, not an app — Info.plist is absent)."""
    name = _NAME_OVERRIDES.get(name, name)
    r = sp.run(["mdfind", f'kMDItemKind == "Application" && kMDItemFSName == "{name}.app"'],
               capture_output=True, text=True, timeout=5)
    for path in r.stdout.splitlines():
        path = path.strip()
        if path and os.path.isfile(os.path.join(path, "Contents", "Info.plist")):
            return path
    return None

def _icns(app):
    r=sp.run(["defaults","read",f"{app}/Contents/Info.plist","CFBundleIconFile"],
             capture_output=True,text=True,timeout=5)
    ic=r.stdout.strip()
    if not ic: return None
    if not ic.endswith(".icns"): ic+=".icns"
    p=os.path.join(app,"Contents","Resources",ic); return p if os.path.exists(p) else None

def _sips_b64(src, sz=32):
    f=tempfile.NamedTemporaryFile(suffix=".png",delete=False); tmp=f.name; f.close()
    try:
        sp.run(["sips","-s","format","png","-Z",str(sz),src,"--out",tmp],capture_output=True,timeout=10)
        with open(tmp,"rb") as f: return base64.b64encode(f.read()).decode()
    finally: os.unlink(tmp) if os.path.exists(tmp) else None

def _jxa_b64(app, sz=32):
    f=tempfile.NamedTemporaryFile(suffix=".png",delete=False); tmp=f.name; f.close()
    try:
        js=_JXA.replace("APP",app).replace("SZ",str(sz*4)).replace("OUT",tmp)
        sp.run(["osascript","-l","JavaScript","-e",js],capture_output=True,timeout=10)
        if os.path.exists(tmp) and os.path.getsize(tmp)>0:
            sp.run(["sips","-Z",str(sz),tmp,"--out",tmp],capture_output=True,timeout=5)
            with open(tmp,"rb") as f: return base64.b64encode(f.read()).decode()
    finally: os.unlink(tmp) if os.path.exists(tmp) else None

# ── synthetic fallback (used when the real `.app` isn't installed) ─────────
def _stable_hue(name):
    """Deterministic hue 0..359 from app name — stable across runs/machines."""
    h = 0
    for ch in name:
        h = (h * 31 + ord(ch)) & 0xFFFFFFFF
    return h % 360


def _initial_for(name):
    """Pick a 1–2 letter initial — `Visual Studio Code` → `VS`, `Zap` → `Z`."""
    words = [w for w in re.split(r"[^A-Za-z0-9]+", name) if w]
    if not words: return "?"
    if len(words) == 1: return words[0][0].upper()
    return (words[0][0] + words[1][0]).upper()


def _synth_symbol(name, slug):
    """Coloured disc + initial — visual placeholder for missing apps.

    Hue is name-stable so the same app always renders the same colour.
    """
    hue = _stable_hue(name)
    initial = _initial_for(name)
    fs = "14" if len(initial) == 1 else "11"
    return (
        f'<symbol id="icon-{slug}" viewBox="0 0 32 32">'
        f'<circle cx="16" cy="16" r="15" fill="hsl({hue}, 60%, 50%)"/>'
        f'<text x="16" y="21" text-anchor="middle" font-size="{fs}" '
        f'font-weight="700" fill="white" '
        f'font-family="-apple-system, system-ui, sans-serif">{initial}</text>'
        f'</symbol>'
    )


def _real_symbol(name, slug, b64):
    return (
        f'<symbol id="icon-{slug}" viewBox="0 0 32 32">'
        f'<image width="32" height="32" href="data:image/png;base64,{b64}"/>'
        f'</symbol>'
    )


def extract_icons(names):
    """Return {name: <symbol>…</symbol>} for every requested name.

    Real .app bundles produce PNG-backed symbols (extracted via icns or AppKit).
    Apps that aren't installed get a synthetic coloured initial-disc — guarantees
    every name in the input is renderable as `<use href="#icon-<slug>">` even
    when the app is uninstalled or unindexed by Spotlight.
    """
    out = {}
    for name in names:
        if not name: continue
        slug = icon_slug(name)
        b64 = None
        try:
            app = _find(name)
            if app:
                ic = _icns(app)
                b64 = _sips_b64(ic) if ic else _jxa_b64(app)
        except (sp.TimeoutExpired, OSError):
            pass
        out[name] = _real_symbol(name, slug, b64) if b64 else _synth_symbol(name, slug)
    return out
