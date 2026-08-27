#!/usr/bin/env python3
"""
Cross-platform path-based username retrieval hook for Claude Code.

Retrieves the username as it appears in local filesystem paths using a
path-only fallback strategy. Extracts the username exclusively from home
directory path components. Returns empty string if the path-based username
cannot be determined.

Returns ONLY the username to stdout. Returns empty string if all methods fail.

Trigger: SessionStart with any source (no source restrictions)
"""

import os
import sys
from pathlib import Path


def _is_valid_username(username: str) -> bool:
    """Minimal validation to reject paths and empty values.

    Args:
        username: Candidate username string.

    Returns:
        True if username appears valid, False otherwise.
    """
    if not username:
        return False
    return not (os.sep in username or '/' in username or '\\' in username)


def _name_from_path(path_str: str) -> str | None:
    """Extract and validate username from a filesystem path.

    Args:
        path_str: Filesystem path to extract the last component from.

    Returns:
        Validated username from path's last component, or None.
    """
    if not path_str:
        return None
    try:
        name = Path(path_str).name
        if name and _is_valid_username(name):
            return name
    except Exception:
        pass
    return None


def _try_sudo_user_home() -> str | None:
    """Resolve the original user's home directory name under sudo.

    Under sudo, Path.home() returns /root. This function detects the
    SUDO_USER environment variable and resolves the original user's
    home directory via the password database, extracting the path-based
    username from pw_dir.

    Returns:
        Path-based username of the original sudo invoker, or None.
    """
    if sys.platform != 'win32':
        sudo_user = os.environ.get('SUDO_USER', '').strip()
        if not sudo_user:
            return None
        try:
            import pwd

            home_dir = pwd.getpwnam(sudo_user).pw_dir
            return _name_from_path(home_dir)
        except Exception:
            return None
    return None


def _try_home_path() -> str | None:
    """Extract username from home directory path.

    Uses Path.home(), os.path.expanduser, and USERPROFILE as
    progressively broader fallbacks, all path-based.

    Returns:
        Username extracted from home path, None otherwise.
    """
    try:
        home = Path.home()
        if home.name and _is_valid_username(home.name):
            return home.name
    except Exception:
        pass

    try:
        home_str = os.path.expanduser('~')
        if home_str and home_str != '~':
            name = _name_from_path(home_str)
            if name:
                return name
    except Exception:
        pass

    userprofile = os.environ.get('USERPROFILE', '')
    if userprofile:
        name = _name_from_path(userprofile)
        if name:
            return name

    return None


def _try_pwd_home() -> str | None:
    """Resolve username from the password database home directory path.

    Uses pw_dir (home directory path) instead of pw_name (login name)
    to ensure the returned value matches filesystem paths.

    Returns:
        Path-based username from password database, or None.
    """
    if sys.platform != 'win32':
        try:
            import pwd

            result = _name_from_path(pwd.getpwuid(os.getuid()).pw_dir)
            if result:
                return result
        except Exception:
            pass

        try:
            import pwd

            result = _name_from_path(pwd.getpwuid(os.geteuid()).pw_dir)
            if result:
                return result
        except Exception:
            pass

    return None


def get_username() -> str:
    """Get the username as it appears in local filesystem paths.

    Uses a path-only fallback chain. Returns empty string if the
    path-based username cannot be determined. Never returns a
    username from non-path sources.

    Returns:
        Username string matching filesystem paths, or empty string if
        all path-based methods fail.
    """
    # 1. Sudo check first (Unix): Path.home() returns /root under sudo
    result = _try_sudo_user_home()
    if result:
        return result

    # 2. Path-based primary: extract from home directory path
    result = _try_home_path()
    if result:
        return result

    # 3. Unix pwd.pw_dir backup: home directory from password database
    result = _try_pwd_home()
    if result:
        return result

    # No login-name fallback: return empty string
    return ''


def main() -> None:
    """Main hook execution function."""
    try:
        username = get_username()

        if username:
            print(username)

        sys.exit(0)

    except Exception:
        sys.exit(0)


if __name__ == '__main__':
    main()
