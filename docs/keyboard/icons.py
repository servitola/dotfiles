"""Extract app icons from macOS as base64 PNG for SVG embedding."""
import base64, os, subprocess, tempfile

_NAME_FIXES = {"Iina": "IINA", "XCode": "Xcode"}


def _find_app_icon(name):
    name = _NAME_FIXES.get(name, name)
    r = subprocess.run(["mdfind", f'kMDItemKind == "Application" && kMDItemFSName == "{name}.app"'],
                       capture_output=True, text=True, timeout=5)
    path = r.stdout.strip().split("\n")[0]
    if not path or not os.path.isdir(path): return None
    r2 = subprocess.run(["defaults", "read", f"{path}/Contents/Info.plist", "CFBundleIconFile"],
                        capture_output=True, text=True, timeout=5)
    icon = r2.stdout.strip()
    if not icon: return None
    if not icon.endswith(".icns"): icon += ".icns"
    p = os.path.join(path, "Contents", "Resources", icon)
    return p if os.path.exists(p) else None


def _to_b64(icns, size=32):
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        tmp = f.name
    try:
        subprocess.run(["sips", "-s", "format", "png", "-Z", str(size),
                        icns, "--out", tmp], capture_output=True, timeout=10)
        with open(tmp, "rb") as f: return base64.b64encode(f.read()).decode()
    finally:
        if os.path.exists(tmp): os.unlink(tmp)


def extract_icons(app_names):
    """Return {app_name: base64_png} for each found app."""
    icons = {}
    for name in app_names:
        try:
            icns = _find_app_icon(name)
            if icns:
                b = _to_b64(icns)
                if b: icons[name] = b
        except (subprocess.TimeoutExpired, OSError): pass
    return icons
