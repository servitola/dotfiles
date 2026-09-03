"""Resolve `@KEY` app targets in layout files against the dotfiles constants.

A chord that binds "the browser I use" rather than a specific app writes
`app = "@APP_BROWSER"`; Hammerspoon resolves it at load time
(HotKeys.spoon/init.lua) and these tools resolve it the same way, so bundle
ids and generated rows name the real app.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "constants"))

from constants import K  # noqa: E402


def resolve(target: str) -> str | None:
    """Real app name for a target. None when a `@KEY` names no constant."""
    if not target.startswith("@"):
        return target
    return K.get(target[1:])
