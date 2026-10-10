#!/usr/bin/env python3
"""Sync a friend's skill allowlist into their .claude/settings.json.

Model: the symlinks inside <friend>/.claude/skills/ are the single source of
truth for what a friend may use. Everything in the owner's ~/.claude/skills
that is NOT linked into the friend folder gets `skillOverrides: "off"`, which
hides it from both the model and the user (CC `skillOverrides`, absent = on).

A skill the friend creates locally (lives in their skills dir but not in
~/.claude/skills) is never in the off-set and stays on as a project skill.

Personal skills: anything under <friend>/user-skills/<name>/ is mirrored into
<friend>/.claude/skills/<name> (a `../../user-skills/<name>` symlink) on every
sync. Because it is not in the owner's ~/.claude/skills it never lands in the
off-set — so it stays ON, is visible ONLY to that friend, and (via the topic
`.claude -> ../.claude` inheritance) works across ALL their topics. Stale
mirror links whose user-skills source is gone are pruned.

Usage:
    sync-friend-skills.py <friend-root> [<friend-root> ...]
    sync-friend-skills.py --all          # every root in serho AUTO_BIND_MAP
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

USER_SKILLS = Path.home() / ".claude" / "skills"
SERHO_ENV = Path.home() / "projects" / "serho" / ".env"
USER_SKILLS_MARK = "user-skills/"  # substring marking a personal-skill mirror link


def friend_roots_from_env() -> list[Path]:
    """Every AUTO_BIND_MAP value in serho/.env that has a .claude/settings.json."""
    if not SERHO_ENV.exists():
        raise SystemExit(f"no {SERHO_ENV} — pass friend roots explicitly")
    line = next(
        (l for l in SERHO_ENV.read_text().splitlines() if l.startswith("AUTO_BIND_MAP=")),
        "",
    )
    mapping = json.loads(line.split("=", 1)[1]) if "=" in line else {}
    roots = []
    for path in dict.fromkeys(mapping.values()):  # dedupe, keep order
        if (Path(path) / ".claude" / "settings.json").exists():
            roots.append(Path(path))
    return roots


def skill_names(skills_dir: Path) -> set[str]:
    if not skills_dir.is_dir():
        return set()
    return {
        child.name
        for child in skills_dir.iterdir()
        if (child.is_dir() or child.is_symlink()) and not child.name.startswith(".")
    }


def mirror_user_skills(skills_dir: Path, user_skills_dir: Path) -> list[str]:
    """Mirror <root>/user-skills/* into <root>/.claude/skills/ and prune stale.

    Returns the names of the personal skills now linked. Only ever touches
    symlinks pointing into user-skills/ — never clobbers an owner-managed link
    to ~/.claude/skills or a detached skill.
    """
    skills_dir.mkdir(parents=True, exist_ok=True)

    # Prune mirror links whose user-skills source has disappeared.
    for child in skills_dir.iterdir():
        if child.is_symlink() and USER_SKILLS_MARK in os.readlink(child) and not child.exists():
            child.unlink()

    linked: list[str] = []
    if not user_skills_dir.is_dir():
        return linked
    for skill in sorted(user_skills_dir.iterdir()):
        if not skill.is_dir() or skill.name.startswith("."):
            continue
        link = skills_dir / skill.name
        rel = os.path.relpath(skill, skills_dir)  # ../../user-skills/<name>
        if link.is_symlink():
            if os.readlink(link) == rel:
                linked.append(skill.name)
                continue
            if USER_SKILLS_MARK in os.readlink(link):
                link.unlink()  # rewrite our own stale link
            else:
                continue  # owner-managed link with the same name wins; don't touch
        elif link.exists():
            continue  # a real dir/file already sits here; leave it
        link.symlink_to(rel)
        linked.append(skill.name)
    return linked


def sync(friend_root: Path) -> None:
    root = friend_root.expanduser().resolve()
    settings_path = root / ".claude" / "settings.json"
    if not settings_path.exists():
        raise SystemExit(f"no settings.json at {settings_path}")

    personal = mirror_user_skills(root / ".claude" / "skills", root / "user-skills")

    linked = skill_names(root / ".claude" / "skills")
    everything = skill_names(USER_SKILLS)
    off = sorted(everything - linked)

    data = json.loads(settings_path.read_text(encoding="utf-8"))
    data["skillOverrides"] = {name: "off" for name in off}
    settings_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(f"{root.name}: {len(linked)} ON, {len(off)} off")
    print("  ON: " + ", ".join(sorted(linked)))
    if personal:
        print("  personal: " + ", ".join(sorted(personal)))


def main(argv: list[str]) -> None:
    if not argv:
        raise SystemExit(__doc__)
    if argv == ["--all"]:
        roots = friend_roots_from_env()
        print(f"--all: {len(roots)} friend roots")
        for root in roots:
            sync(root)
        return
    for arg in argv:
        sync(Path(arg))


if __name__ == "__main__":
    main(sys.argv[1:])
