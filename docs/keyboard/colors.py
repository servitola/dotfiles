"""Apple-style color palette and category classification using source tags."""
PALETTE = {
    "key_bg": "#f5f5f7", "key_bg_bound": "#ffffff",
    "key_border": "#d2d2d7", "key_border_unbound": "#e8e8ed",
    "text": "#1d1d1f", "text_dim": "#c7c7cc",
    "app": "#007aff", "window": "#34c759", "media": "#ff9500",
    "nav": "#5ac8fa", "browser": "#af52de", "system": "#ff3b30",
    "macos": "#86868b", "birman": "#8e8e93", "karabiner": "#a2845e",
}
CATEGORY_LABELS = {
    "app": "Apps", "window": "Window Mgmt", "media": "Media / Audio",
    "nav": "Navigation", "browser": "Browser / Translate", "system": "System",
    "macos": "macOS", "birman": "Birman Layout", "karabiner": "Karabiner",
}
CATEGORY_ICONS = {
    "macos": "apple", "window": "win-icon", "media": "audio-icon",
    "birman": "birman", "karabiner": "karabiner-icon",
}
# fn → category (overrides tag-based detection)
_WIN = {"window."}
_MEDIA_L = {"vol", "volume", "⏮", "⏭", "▶", "⏸", "play", "prev_track", "next_track"}
_NAV_L = {"←", "→", "↑", "↓", "pgup", "pgdn", "home", "end", "↩", "enter"}
_BROWSER = {"browser_", "translate_"}
_SYS = {"hammerspoon_reload", "vpn.", "wallpaper_", "system_health", "screenshot_ai"}
_TAG_CAT = {"K": "karabiner", "B": "birman", "\uf8ff": "macos"}


def get_category(entry):
    fn = entry.get("fn", "")
    label = entry.get("label", "").lower()
    if fn:
        if any(fn.startswith(p) for p in _BROWSER): return "browser"
        if any(fn.startswith(p) for p in _SYS): return "system"
        if any(p in fn for p in _WIN): return "window"
        if fn.startswith(("musicapp.", "audio.")): return "media"
    if any(m in label for m in _MEDIA_L): return "media"
    if any(n in label for n in _NAV_L): return "nav"
    if entry.get("app"): return "app"
    # Use source tag from comment documentation
    tag = entry.get("source_tag", "")
    if tag in _TAG_CAT: return _TAG_CAT[tag]
    return "app"
