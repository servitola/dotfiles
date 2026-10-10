#!/usr/bin/env python3
"""One entry point for the skill zoo: where things live, who sees them, what drifted.

Wraps the existing tools (skill-attach, user-skill,
bind-topic-skill.sh, sync-friend-skills) instead of replacing them — the
symlink model on disk is unchanged. `friend_roots_from_env` and `skill_names`
are imported from sync-friend-skills.py rather than reimplemented: if `doctor`
and the real sync disagreed about what counts as linked, doctor would lie.

Usage:
    skill where <name>              every place the skill is visible
    skill who <friend|me>           what that context actually sees
    skill list                      inventory by source, orphans flagged
    skill give <name> --to <who>    all | <friend> | <path>
    skill doctor                    orphans, broken links, preset drift
"""
from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
DOTFILES = HOME / "projects" / "dotfiles"
TOPICS = HOME / "projects" / "serho_topics"
FRIENDS = HOME / "projects" / "serho-users"
SKILLS = Path(os.environ["DIR_SKILLS"])
PRESETS_FILE = SKILLS / "skill-presets.json"

#: label -> dir. Order matters: first match wins when resolving a skill's home.
SOURCES = {
    "public": SKILLS / "skills",
    "public-detached": SKILLS / "detached_skills",
    "bot-shared": TOPICS / ".claude" / "skills",
}
GLOBAL = HOME / ".claude" / "skills"


def _sync_module():
    """Load sync-friend-skills.py (hyphens block a plain import)."""
    path = DOTFILES / "claude-code" / "scripts" / "sync-friend-skills.py"
    spec = importlib.util.spec_from_file_location("sync_friend_skills", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


SYNC = _sync_module()


def die(msg: str) -> None:
    raise SystemExit(f"skill: {msg}")


def entries(d: Path) -> set[str]:
    return SYNC.skill_names(d)


def friend_roots() -> list[Path]:
    try:
        return [r for r in SYNC.friend_roots_from_env() if FRIENDS in r.parents]
    except SystemExit:
        return sorted(p for p in FRIENDS.iterdir() if (p / ".claude").is_dir()) if FRIENDS.is_dir() else []


def attachment_points() -> list[tuple[str, Path]]:
    """Every dir whose contents make a skill visible to some session."""
    points: list[tuple[str, Path]] = [("глобально (все мои сессии)", GLOBAL)]
    shared = TOPICS / ".claude" / "skills"
    if shared.is_dir():
        points.append(("все мои топики бота", shared))
    for topic in _real_claude_dirs(TOPICS):
        points.append((f"мой топик: {topic.parents[1].name}", topic))
    for root in friend_roots():
        points.append((f"друг: {root.name}", root / ".claude" / "skills"))
        for topic in _real_claude_dirs(root):
            points.append((f"друг {root.name}, топик: {topic.parents[1].name}", topic))
    return points


def _real_claude_dirs(root: Path) -> list[Path]:
    """<root>/*/.claude/skills where .claude is a real dir (not the inherit symlink).

    A topic whose `.claude` is a symlink to ../.claude adds nothing new — it
    just re-exposes the shared set, which is already its own attachment point.
    """
    found: list[Path] = []
    if not root.is_dir():
        return found
    for child in sorted(root.iterdir()):
        if not child.is_dir() or child.name.startswith("."):
            continue
        claude = child / ".claude"
        if not claude.is_dir() or claude.is_symlink():
            continue
        skills = claude / "skills"
        if skills.is_dir() and not skills.is_symlink():
            found.append(skills)
    return found


def home_of(name: str) -> list[str]:
    return [label for label, d in SOURCES.items() if (d / name).exists() or (d / name).is_symlink()]


# ---------------------------------------------------------------- presets


def load_presets() -> dict:
    if not PRESETS_FILE.exists():
        return {"presets": {}, "friends": {}}
    return json.loads(PRESETS_FILE.read_text(encoding="utf-8"))


def expected_for(friend: str, cfg: dict) -> set[str] | None:
    """Skills a friend should have per presets, or None if unmanaged."""
    spec = cfg.get("friends", {}).get(friend)
    if spec is None:
        return None
    want: set[str] = set()
    for preset in spec.get("presets", []):
        want |= set(cfg.get("presets", {}).get(preset, []))
    want |= set(spec.get("extra", []))
    return want


# ---------------------------------------------------------------- commands


def cmd_where(argv: list[str]) -> None:
    if not argv:
        die("нужно имя: skill where <name>")
    name = argv[0]
    src = home_of(name)
    print(f"{name}")
    print(f"  исходник: {', '.join(src) if src else 'НЕ НАЙДЕН ни в одном источнике'}")

    hits = [(label, d) for label, d in attachment_points() if (d / name).is_symlink() or (d / name).is_dir()]
    if not hits:
        print("  виден: НИГДЕ")
        if src and all(s.endswith("detached") for s in src):
            print("  (detached — это нормально, пока не привязан: skill give)")
        return
    print(f"  виден в {len(hits)} местах:")
    for label, d in hits:
        link = d / name
        mark = " ⚠ БИТЫЙ" if link.is_symlink() and not link.exists() else ""
        print(f"    - {label}{mark}")


def cmd_who(argv: list[str]) -> None:
    if not argv:
        die("нужна цель: skill who <friend|me>")
    target = argv[0]

    if target in ("me", "я"):
        print(f"я — глобально: {len(entries(GLOBAL))} скиллов")
        print(f"   + во всех топиках бота: {len(entries(TOPICS / '.claude' / 'skills'))}")
        for topic in _real_claude_dirs(TOPICS):
            print(f"   + топик {topic.parents[1].name}: {len(entries(topic))}")
        return

    root = FRIENDS / target
    if not (root / ".claude").is_dir():
        die(f"нет такого друга: {target}")
    farm = entries(root / ".claude" / "skills")
    settings = root / ".claude" / "settings.json"
    off = {}
    if settings.exists():
        raw = json.loads(settings.read_text(encoding="utf-8")).get("skillOverrides", {})
        off = {k for k, v in raw.items() if v == "off" or v is False}
    leaking = sorted(entries(GLOBAL) - off - farm)

    print(f"{target}: видит {len(farm)} скиллов, погашено {len(off)}")
    print("  " + ", ".join(sorted(farm)))
    personal = entries(root / "user-skills")
    if personal:
        print(f"  личные: {', '.join(sorted(personal))}")
    if leaking:
        print(f"  ⚠ УТЕЧКА (не погашено и не залинковано): {', '.join(leaking)}")
        print("    почини: sync-friend-skills " + str(root))


def cmd_list(argv: list[str]) -> None:
    attached: set[str] = set()
    for _, d in attachment_points():
        attached |= entries(d)

    for label, d in SOURCES.items():
        names = entries(d)
        if not names:
            continue
        print(f"{label}  ({len(names)})  {d}")
        if label == "public-detached":
            orphans = sorted(n for n in names if n not in attached and not (GLOBAL / n).exists())
            if orphans:
                print(f"   ⚠ нигде не привязано: {', '.join(orphans)}")


def cmd_give(argv: list[str]) -> None:
    if len(argv) < 3 or argv[1] != "--to":
        die("формат: skill give <name> --to all|<friend>|<path>")
    name, target = argv[0], argv[2]
    src = home_of(name)
    if not src:
        die(f"скилл не найден ни в одном источнике: {name}")
    detached = all(s.endswith("detached") for s in src)

    if target == "all":
        roots = friend_roots()
        if not roots:
            die("не нашёл друзей")
        for root in roots:
            _attach(name, root, detached)
        cfg = load_presets()
        base = cfg.setdefault("presets", {}).setdefault("base", [])
        if name not in base:
            base.append(name)
            base.sort()
            PRESETS_FILE.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"добавлен в пресет base ({PRESETS_FILE.name})")
        _sync_all()
        return

    root = FRIENDS / target if (FRIENDS / target / ".claude").is_dir() else Path(target).expanduser()
    if not root.is_dir():
        die(f"не понял цель: {target}")
    _attach(name, root, detached)
    if FRIENDS in root.parents or root.parent == FRIENDS:
        _sync_all()


def _attach(name: str, root: Path, detached: bool) -> None:
    """Detached skills MUST go through skill-attach — a direct ln -s to
    ~/.claude/skills/<detached> yields a broken link (the historic drift bug)."""
    if detached:
        sys.stdout.flush()
        subprocess.run(["skill-attach", name, str(root)], check=True)
        return
    dest = root / ".claude" / "skills"
    dest.mkdir(parents=True, exist_ok=True)
    link = dest / name
    if link.is_symlink() or link.exists():
        print(f"{root.name}: {name} уже есть")
        return
    link.symlink_to(GLOBAL / name)
    print(f"{root.name}: + {name}")


def _sync_all() -> None:
    sys.stdout.flush()  # our prints are buffered, the child's are not
    subprocess.run([sys.executable, str(DOTFILES / "claude-code" / "scripts" / "sync-friend-skills.py"), "--all"], check=True)


def cmd_doctor(argv: list[str]) -> None:
    problems = 0

    broken: list[str] = []
    for label, d in attachment_points():
        for child in sorted(d.iterdir()) if d.is_dir() else []:
            if child.is_symlink() and not child.exists():
                broken.append(f"{label}: {child.name} -> {os.readlink(child)}")
    if broken:
        problems += len(broken)
        print(f"⚠ битые симлинки ({len(broken)}):")
        for b in broken:
            print(f"   {b}")

    attached: set[str] = set()
    for _, d in attachment_points():
        attached |= entries(d)
    orphans: list[str] = []
    for label in ("public-detached",):
        for n in sorted(entries(SOURCES[label])):
            if n not in attached and not (GLOBAL / n).exists():
                orphans.append(f"{label}: {n}")
    if orphans:
        problems += len(orphans)
        print(f"⚠ скиллы, которые нигде не видны ({len(orphans)}):")
        for o in orphans:
            print(f"   {o}")

    leaks = 0
    for root in friend_roots():
        settings = root / ".claude" / "settings.json"
        if not settings.exists():
            continue
        raw = json.loads(settings.read_text(encoding="utf-8")).get("skillOverrides", {})
        off = {k for k, v in raw.items() if v == "off" or v is False}
        farm = entries(root / ".claude" / "skills")
        leaking = sorted(entries(GLOBAL) - off - farm)
        if leaking:
            leaks += 1
            problems += 1
            print(f"⚠ {root.name} видит лишнее: {', '.join(leaking)}")
    if not leaks:
        print(f"✓ утечек нет ({len(friend_roots())} друзей)")

    cfg = load_presets()
    if cfg.get("friends"):
        drifted = 0
        for root in friend_roots():
            want = expected_for(root.name, cfg)
            if want is None:
                print(f"· {root.name}: вне пресетов (ручной набор)")
                continue
            have = entries(root / ".claude" / "skills") - entries(root / "user-skills")
            missing, extra = sorted(want - have), sorted(have - want)
            if missing or extra:
                drifted += 1
                problems += 1
                print(f"⚠ {root.name} разошёлся с пресетом:")
                if missing:
                    print(f"   не хватает: {', '.join(missing)}")
                if extra:
                    print(f"   лишнее: {', '.join(extra)}")
        if not drifted:
            print("✓ все друзья совпадают с пресетами")
    else:
        print("· пресеты не настроены — создай skill-presets.json (skill doctor --init)")

    print(f"\n{'проблем: ' + str(problems) if problems else 'всё чисто'}")


def cmd_doctor_init() -> None:
    """Bootstrap presets from current reality: base = what every friend shares."""
    roots = friend_roots()
    if not roots:
        die("не нашёл друзей")
    farms = {r.name: entries(r / ".claude" / "skills") - entries(r / "user-skills") for r in roots}
    base = sorted(set.intersection(*farms.values()))
    cfg = {
        "presets": {"base": base},
        "friends": {n: {"presets": ["base"], "extra": sorted(f - set(base))} for n, f in farms.items()},
    }
    PRESETS_FILE.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"создан {PRESETS_FILE}")
    print(f"  base: {len(base)} скиллов, общих у всех {len(farms)} друзей")
    for n, f in sorted(farms.items()):
        extra = sorted(f - set(base))
        if extra:
            print(f"  {n}: +{len(extra)} ({', '.join(extra)})")


COMMANDS = {
    "where": cmd_where,
    "who": cmd_who,
    "list": cmd_list,
    "give": cmd_give,
    "doctor": cmd_doctor,
}


def main(argv: list[str]) -> None:
    if not argv or argv[0] in ("-h", "--help", "help"):
        raise SystemExit(__doc__)
    cmd, rest = argv[0], argv[1:]
    if cmd == "doctor" and rest[:1] == ["--init"]:
        return cmd_doctor_init()
    if cmd not in COMMANDS:
        die(f"неизвестная команда: {cmd}\n{__doc__}")
    COMMANDS[cmd](rest)


if __name__ == "__main__":
    main(sys.argv[1:])
