"""Constants of this machine, for Python consumers.

    import sys; sys.path.insert(0, "/Users/servitola/projects/dotfiles/constants")
    from constants import K
    K["TG_CHAT_MAIN"]

Values already exist in os.environ for anything started from a zsh shell; this
loader exists for processes that do not inherit one (launchd, MCP servers).
"""

from pathlib import Path

_HOME = str(Path.home())
_FILE = Path(__file__).resolve().parents[1] / "constants.env"


def load() -> dict[str, str]:
    consts: dict[str, str] = {}
    for line in _FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, value = line.partition("=")
        consts[key.strip()] = value.replace("$HOME", _HOME)
    return consts


K = load()
