"""Shared helpers: load cities, geocode, JSON IO."""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CITIES_PATH = HERE / "_cities.json"

_IATA_TO_NAME_CACHE: dict[str, str] | None = None


def load_cities() -> dict[str, dict]:
    with CITIES_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def _has_cyrillic(s: str) -> bool:
    return any("А" <= c <= "я" or c == "ё" or c == "Ё" for c in s)


def iata_to_name() -> dict[str, str]:
    """IATA code → preferred display name (Cyrillic if available)."""
    global _IATA_TO_NAME_CACHE
    if _IATA_TO_NAME_CACHE is not None:
        return _IATA_TO_NAME_CACHE
    cities = load_cities()
    result: dict[str, str] = {}
    for key, val in cities.items():
        iata = val.get("iata")
        if not iata:
            continue
        if key == iata:
            continue
        existing = result.get(iata)
        if existing is None:
            result[iata] = key
        elif _has_cyrillic(key) and not _has_cyrillic(existing):
            result[iata] = key
    _IATA_TO_NAME_CACHE = result
    return result


def resolve_display_city(value: str) -> tuple[str, str | None]:
    """Return (display_name, code) — Cyrillic name preferred + IATA in parens.

    Input may be IATA ('LCA'), Russian name ('Ларнака'), or already 'Name (CODE)'.
    Falls back gracefully.
    """
    if not value or value == "???":
        return "—", None
    s = value.strip()
    if "(" in s and ")" in s:
        head, rest = s.split("(", 1)
        return head.strip(), rest.rstrip(") ").strip() or None
    if s.isupper() and len(s) == 3 and s.isalpha():
        name = iata_to_name().get(s)
        if name:
            return name, s
        return s, None
    cities = load_cities()
    if s in cities and cities[s].get("iata"):
        return s, cities[s]["iata"]
    for key, val in cities.items():
        if key.lower() == s.lower() and val.get("iata"):
            return key, val["iata"]
    return s, None


def lookup_city(name: str) -> tuple[float, float] | None:
    cities = load_cities()
    if name in cities:
        c = cities[name]
        return c["lat"], c["lon"]
    lo = name.lower()
    for key, val in cities.items():
        if key.lower() == lo:
            return val["lat"], val["lon"]
    return None


def resolve_coords(stop: dict) -> tuple[float, float]:
    if "lat" in stop and "lon" in stop:
        return float(stop["lat"]), float(stop["lon"])
    coords = lookup_city(stop["name"])
    if coords is None:
        raise SystemExit(
            f"Не знаю координат для '{stop['name']}'. Добавь в JSON поля lat/lon."
        )
    return coords


def load_data(arg: str) -> dict:
    if arg == "-":
        return json.load(sys.stdin)
    return json.loads(Path(arg).read_text(encoding="utf-8"))
