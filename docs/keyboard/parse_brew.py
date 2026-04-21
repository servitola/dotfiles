"""Parse Homebrew brewfile to extract app descriptions for tooltips."""
import os, re

_BREW = os.path.join(os.path.dirname(__file__), "..", "..", "homebrew", "brewfile")
_CASK = re.compile(r'^cask\s+"([^"]+)"')


def parse_brew_descriptions():
    """Return {app_name_lower: description} from brewfile comments."""
    if not os.path.exists(_BREW): return {}
    descs, prev_comment = {}, ""
    with open(_BREW, encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if s.startswith("#"):
                prev_comment = s.lstrip("# ").strip()
            else:
                m = _CASK.match(s)
                if m and prev_comment:
                    descs[m.group(1).lower()] = prev_comment
                if s and not s.startswith("#"):
                    prev_comment = ""
    return descs


# App display name → cask name mapping
_CASK_ALIAS = {
    "Visual Studio Code": "visual-studio-code", "VS Code": "visual-studio-code",
    "Rider": "rider", "Fork": "fork", "Firefox": "firefox",
    "Telegram": "telegram", "Iina": "iina", "IINA": "iina",
    "Yandex": "yandex", "Shottr": "shottr", "Maccy": "maccy",
    "Warp": "warp", "iTerm": "iterm2", "Google Chrome": "google-chrome",
    "Raycast": "raycast", "OrbStack": "orbstack", "Claude": "claude",
    "zoom.us": "zoom", "VoiceInk": "voiceink",
}


def get_brew_desc(app_name, brew_descs):
    """Lookup brew description for an app name."""
    cask = _CASK_ALIAS.get(app_name, app_name.lower().replace(" ", "-"))
    return brew_descs.get(cask, "")
