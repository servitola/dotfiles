#!/usr/bin/env python3
"""check-models — verify availability of all LiteLLM deployments and track health.

Checks each configured model against its provider's live model catalog:

  OpenRouter  GET /api/v1/models          (public, no auth)
  Groq        GET /openai/v1/models       (auth: $GROQ_API_KEY)
  NVIDIA NIM  GET /v1/models              (auth: $NVIDEA_API_KEY)
  GitHub      GET /v1/models              (auth: $GITHUB_API_TOKEN)
  Mistral     GET /v1/models              (auth: $MISTRAL_API_KEY)
  Cerebras    GET /v1/models              (auth: $CEREBRAS_API_KEY)
  SambaNova   GET /v1/models              (auth: $SAMBANOVA_API_KEY)
  Chutes      GET /v1/models              (auth: $CHUTES_API_KEY)
  Together    GET /v1/models              (auth: $TOGETHER_API_KEY)
  LLM7        GET /v1/models              (public, no auth)
  Gemini      GET /v1beta/models          (auth: $GEMINI_API_KEY)
  Z.AI        no list endpoint            (always assumed ok)
  Ollama      GET /api/tags               (local)

Tracks per-slug availability in model-health.json.  Deployments unavailable
for >STALE_DAYS are auto-removed from config.yaml (with safety guards).
Reports new free OpenRouter models not yet in the config.

Usage:
    python3 check-models.py              # full check + auto-remove + restart
    python3 check-models.py --dry-run    # report only, no config changes
    python3 check-models.py --discover   # show all new OpenRouter free models
"""

from __future__ import annotations

import json
import os
import re
import ssl
import subprocess
import sys
from datetime import date, datetime
from pathlib import Path
from typing import NamedTuple
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

# ── constants ────────────────────────────────────────────────────────────────

STALE_DAYS = 7

SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR.parent / "config.yaml"
STATE_PATH = SCRIPT_DIR.parent / "model-health.json"
VERIFY_SCRIPT = SCRIPT_DIR / "verify-free-only.sh"
COMPOSE_DIR = SCRIPT_DIR.parent

PROTECTED_NAMES = {"embed"}

OPENROUTER_API_BASE = "https://openrouter.ai/api/v1"
NVIDIA_API_BASE = "https://integrate.api.nvidia.com/v1"
GITHUB_API_BASE = "https://models.github.ai/inference"
CEREBRAS_API_BASE = "https://api.cerebras.ai/v1"
SAMBANOVA_API_BASE = "https://api.sambanova.ai/v1"
CHUTES_API_BASE = "https://llm.chutes.ai/v1"
TOGETHER_API_BASE = "https://api.together.xyz/v1"
LLM7_API_BASE = "https://api.llm7.io/v1"

# ANSI colors (match update_all.sh)
GREEN = "\033[0;92m"
YELLOW = "\033[0;33m"
RED = "\033[0;31m"
CYAN = "\033[0;36m"
DIM = "\033[2m"
BOLD = "\033[1m"
NC = "\033[0m"

# SSL context: secure by default; set CHECK_MODELS_INSECURE=1 for corporate proxies
_SSL_CTX = ssl.create_default_context()
if os.environ.get("CHECK_MODELS_INSECURE"):
    _SSL_CTX.check_hostname = False
    _SSL_CTX.verify_mode = ssl.CERT_NONE


# ── data types ───────────────────────────────────────────────────────────────

class Deployment(NamedTuple):
    model_name: str       # alias: "nemotron", "coding", "vision", …
    model_slug: str       # e.g. "openai/nvidia/nemotron-3-super-120b-a12b:free"
    api_base: str | None
    provider: str         # "openrouter", "groq", "nvidia", "github", "zai", "ollama"
    start_line: int       # 1-indexed, the "  - model_name:" line
    end_line: int         # 1-indexed, last content line of this block
    comment_start: int    # 1-indexed, first comment/blank line above this block


# ── config parsing ───────────────────────────────────────────────────────────

def _classify_provider(model: str, api_base: str | None) -> str:
    if model.startswith("groq/"):
        return "groq"
    if model.startswith("zai/"):
        return "zai"
    if model.startswith("gemini/"):
        return "gemini"
    if model.startswith("mistral/"):
        return "mistral"
    if model.startswith("ollama/"):
        return "ollama"
    if api_base == OPENROUTER_API_BASE:
        return "openrouter"
    if api_base == NVIDIA_API_BASE:
        return "nvidia"
    if api_base == GITHUB_API_BASE:
        return "github"
    if api_base == CEREBRAS_API_BASE:
        return "cerebras"
    if api_base == SAMBANOVA_API_BASE:
        return "sambanova"
    if api_base == CHUTES_API_BASE:
        return "chutes"
    if api_base == TOGETHER_API_BASE:
        return "together"
    if api_base == LLM7_API_BASE:
        return "llm7"
    return "unknown"


def parse_deployments(yaml_text: str) -> list[Deployment]:
    """Parse config.yaml into Deployment tuples with line ranges."""
    lines = yaml_text.splitlines()
    raw: list[dict] = []
    in_model_list = False
    model_list_end = 0  # 1-indexed line where model_list section ends
    current: dict | None = None

    for lineno_0, line in enumerate(lines):
        lineno = lineno_0 + 1

        if line.startswith("model_list:"):
            in_model_list = True
            continue
        if in_model_list and re.match(r"^[A-Za-z_]+:", line):
            # top-level key ends model_list; last content line is previous
            model_list_end = lineno - 1
            in_model_list = False
        if not in_model_list:
            continue

        m = re.match(r"^  - model_name:\s*(.*)$", line)
        if m:
            if current is not None:
                current["end_line"] = lineno - 1
                raw.append(current)
            current = {
                "model_name": m.group(1).strip(),
                "model": None,
                "api_base": None,
                "start_line": lineno,
                "end_line": None,
            }
            continue

        if current is None:
            continue

        m2 = re.match(r"^      model:\s*(.*)$", line)
        if m2 and current["model"] is None:
            current["model"] = m2.group(1).strip().strip("\"'")
            continue

        m3 = re.match(r"^      api_base:\s*(.*)$", line)
        if m3 and current["api_base"] is None:
            current["api_base"] = m3.group(1).strip().strip("\"'")

    # if model_list runs to EOF (no subsequent top-level key), set boundary
    if in_model_list:
        model_list_end = len(lines)

    # close last block — end_line is the last content line within model_list
    if current is not None:
        end = model_list_end
        # trim trailing blank lines within model_list
        for i in range(model_list_end - 1, current["start_line"] - 1, -1):
            if lines[i].strip():
                end = i + 1
                break
        current["end_line"] = end
        raw.append(current)

    # fix overlapping end_lines: each block ends at next block's start - 1
    for i in range(len(raw) - 1):
        if raw[i]["end_line"] >= raw[i + 1]["start_line"]:
            raw[i]["end_line"] = raw[i + 1]["start_line"] - 1

    # compute comment_start for each block (walk backward from start_line)
    deployments = []
    for i, r in enumerate(raw):
        if r["model"] is None:
            continue
        comment_start = r["start_line"]
        prev_end = raw[i - 1]["end_line"] if i > 0 else 0
        for ln in range(r["start_line"] - 1, prev_end, -1):
            line_text = lines[ln - 1]  # 0-indexed
            stripped = line_text.strip()
            if stripped == "" or stripped.startswith("#"):
                comment_start = ln
            else:
                break

        provider = _classify_provider(r["model"], r["api_base"])
        deployments.append(Deployment(
            model_name=r["model_name"],
            model_slug=r["model"],
            api_base=r["api_base"],
            provider=provider,
            start_line=r["start_line"],
            end_line=r["end_line"],
            comment_start=comment_start,
        ))

    return deployments


# ── provider API fetchers ────────────────────────────────────────────────────

def _http_json(url: str, headers: dict | None = None, timeout: int = 15) -> dict | None:
    """GET JSON from url. Returns None on any error."""
    req = Request(url)
    req.add_header("User-Agent", "check-models/1.0")
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urlopen(req, timeout=timeout, context=_SSL_CTX) as resp:
            return json.loads(resp.read().decode())
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None


def fetch_openrouter_models() -> set[str] | None:
    """Return set of model IDs available on OpenRouter, or None on failure."""
    data = _http_json(f"{OPENROUTER_API_BASE}/models")
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_groq_models() -> set[str] | None:
    key = os.environ.get("GROQ_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        "https://api.groq.com/openai/v1/models",
        headers={"Authorization": f"Bearer {key}"},
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_nvidia_models() -> set[str] | None:
    # Host env uses NVIDEA_API_KEY (legacy typo); check both spellings
    key = os.environ.get("NVIDIA_API_KEY") or os.environ.get("NVIDEA_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        f"{NVIDIA_API_BASE}/models",
        headers={"Authorization": f"Bearer {key}"},
        timeout=20,
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_github_models() -> set[str] | None:
    key = os.environ.get("GITHUB_API_TOKEN", "")
    if not key:
        return None
    # GitHub Models catalog: models.github.ai/v1/models (OpenAI-compatible)
    data = _http_json(
        "https://models.github.ai/v1/models",
        headers={"Authorization": f"Bearer {key}"},
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_mistral_models() -> set[str] | None:
    key = os.environ.get("MISTRAL_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        "https://api.mistral.ai/v1/models",
        headers={"Authorization": f"Bearer {key}"},
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_cerebras_models() -> set[str] | None:
    key = os.environ.get("CEREBRAS_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        f"{CEREBRAS_API_BASE}/models",
        headers={"Authorization": f"Bearer {key}"},
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_sambanova_models() -> set[str] | None:
    key = os.environ.get("SAMBANOVA_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        f"{SAMBANOVA_API_BASE}/models",
        headers={"Authorization": f"Bearer {key}"},
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_chutes_models() -> set[str] | None:
    key = os.environ.get("CHUTES_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        f"{CHUTES_API_BASE}/models",
        headers={"Authorization": f"Bearer {key}"},
        timeout=20,
    )
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_together_models() -> set[str] | None:
    key = os.environ.get("TOGETHER_API_KEY", "")
    if not key:
        return None
    # Together's /v1/models returns a bare JSON array, not {"data": [...]}.
    data = _http_json(
        f"{TOGETHER_API_BASE}/models",
        headers={"Authorization": f"Bearer {key}"},
        timeout=20,
    )
    if isinstance(data, list):
        return {m["id"] for m in data if isinstance(m, dict) and "id" in m}
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_llm7_models() -> set[str] | None:
    # LLM7 catalog is public (anonymous) — no key required. Returns a bare
    # JSON array, not {"data": [...]}.
    data = _http_json(f"{LLM7_API_BASE}/models")
    if isinstance(data, list):
        return {m["id"] for m in data if isinstance(m, dict) and "id" in m}
    if data and "data" in data:
        return {m["id"] for m in data["data"] if "id" in m}
    return None


def fetch_gemini_models() -> set[str] | None:
    key = os.environ.get("GEMINI_API_KEY", "")
    if not key:
        return None
    data = _http_json(
        f"https://generativelanguage.googleapis.com/v1beta/models?key={key}",
    )
    if data and "models" in data:
        # API returns "models/gemini-2.5-flash" → strip "models/" prefix
        return {m["name"].removeprefix("models/") for m in data["models"] if "name" in m}
    return None


def fetch_ollama_models() -> set[str] | None:
    data = _http_json("http://localhost:11434/api/tags", timeout=5)
    if data and "models" in data:
        names = set()
        for m in data["models"]:
            name = m.get("name", "")
            names.add(name)
            # also add without :latest tag
            if ":" in name:
                names.add(name.rsplit(":", 1)[0])
        return names
    return None


def _lowercase_set(s: set[str] | None) -> set[str] | None:
    """Lowercase all entries for case-insensitive matching."""
    return {x.lower() for x in s} if s is not None else None


def fetch_all_catalogs(raw_openrouter: set[str] | None = None) -> dict[str, set[str] | None]:
    """Fetch model catalogs from all providers. None = API unreachable.

    All IDs are lowercased — providers return inconsistent casing
    (e.g. GitHub: deepseek/deepseek-r1 vs config: deepseek/DeepSeek-R1).
    """
    return {
        "openrouter": _lowercase_set(raw_openrouter if raw_openrouter is not None else fetch_openrouter_models()),
        "groq": _lowercase_set(fetch_groq_models()),
        "nvidia": _lowercase_set(fetch_nvidia_models()),
        "github": _lowercase_set(fetch_github_models()),
        "mistral": _lowercase_set(fetch_mistral_models()),
        "cerebras": _lowercase_set(fetch_cerebras_models()),
        "sambanova": _lowercase_set(fetch_sambanova_models()),
        "chutes": _lowercase_set(fetch_chutes_models()),
        "together": _lowercase_set(fetch_together_models()),
        "llm7": _lowercase_set(fetch_llm7_models()),
        "gemini": _lowercase_set(fetch_gemini_models()),
        "ollama": _lowercase_set(fetch_ollama_models()),
        "zai": None,  # no list endpoint
    }


# ── slug normalization for catalog lookup ────────────────────────────────────

def normalize_slug(deployment: Deployment) -> str:
    """Extract the canonical model ID as the provider's catalog would list it.

    config.yaml uses `openai/<provider-slug>` with explicit api_base for
    OpenRouter / NVIDIA / GitHub. The catalog lists just `<provider-slug>`.
    Groq uses `groq/<slug>`, catalog lists `<slug>`.
    Ollama uses `ollama/<slug>`, tags list `<slug>`.
    """
    slug = deployment.model_slug
    if deployment.provider == "openrouter":
        # openai/nvidia/nemotron-3-super-120b-a12b:free → nvidia/nemotron-3-super-120b-a12b:free
        return slug.removeprefix("openai/")
    if deployment.provider in ("nvidia", "github", "cerebras",
                               "sambanova", "chutes", "together", "llm7"):
        # openai/moonshotai/kimi-k2.5 → moonshotai/kimi-k2.5
        # openai/Qwen/Qwen3.5-397B-A17B-TEE → Qwen/Qwen3.5-397B-A17B-TEE
        return slug.removeprefix("openai/")
    if deployment.provider == "mistral":
        # mistral/codestral-latest → codestral-latest
        return slug.removeprefix("mistral/")
    if deployment.provider == "gemini":
        # gemini/gemini-2.5-flash → gemini-2.5-flash
        return slug.removeprefix("gemini/")
    if deployment.provider == "groq":
        # groq/llama-3.3-70b-versatile → llama-3.3-70b-versatile
        # groq/openai/gpt-oss-120b → openai/gpt-oss-120b
        return slug.removeprefix("groq/")
    if deployment.provider == "ollama":
        # ollama/qwen3.5:35b-a3b → qwen3.5:35b-a3b
        return slug.removeprefix("ollama/")
    return slug


def is_embedding_model(deployment: Deployment) -> bool:
    """Heuristic: embedding models are not in /models endpoints."""
    return "embed" in deployment.model_slug.lower()


# ── availability check ───────────────────────────────────────────────────────

def check_deployments(
    deployments: list[Deployment],
    catalogs: dict[str, set[str] | None],
) -> dict[str, str]:
    """Return {model_slug: status} where status is 'available'|'unavailable'|'assumed_ok'."""
    results: dict[str, str] = {}
    seen_slugs: set[str] = set()

    for dep in deployments:
        if dep.model_slug in seen_slugs:
            continue
        seen_slugs.add(dep.model_slug)

        # protected model names
        if dep.model_name in PROTECTED_NAMES:
            results[dep.model_slug] = "assumed_ok"
            continue

        # embedding models: not in /models endpoints
        if is_embedding_model(dep):
            results[dep.model_slug] = "assumed_ok"
            continue

        # Z.AI: no list endpoint
        if dep.provider == "zai":
            results[dep.model_slug] = "assumed_ok"
            continue

        catalog = catalogs.get(dep.provider)
        if catalog is None:
            # provider API unreachable
            results[dep.model_slug] = "assumed_ok"
            continue

        canonical = normalize_slug(dep).lower()
        if canonical in catalog:
            results[dep.model_slug] = "available"
        else:
            results[dep.model_slug] = "unavailable"

    return results


# ── state management ─────────────────────────────────────────────────────────

def load_state() -> dict:
    if STATE_PATH.is_file():
        try:
            return json.loads(STATE_PATH.read_text("utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return {"_version": 1, "_last_run": None, "models": {}}


def save_state(state: dict) -> None:
    state["_last_run"] = datetime.now().isoformat(timespec="seconds")
    tmp = STATE_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n", "utf-8")
    tmp.rename(STATE_PATH)


def update_state(
    state: dict,
    check_results: dict[str, str],
    deployments: list[Deployment],
) -> dict:
    today = date.today().isoformat()
    models = state.setdefault("models", {})

    # build provider map from deployments
    slug_provider = {d.model_slug: d.provider for d in deployments}

    # update existing entries and add new ones
    for slug, status in check_results.items():
        entry = models.get(slug, {})
        entry["provider"] = slug_provider.get(slug, entry.get("provider", "unknown"))
        entry["last_checked"] = today

        if status in ("available", "assumed_ok"):
            entry["status"] = status
            entry["first_unavailable"] = None
        else:  # unavailable
            entry["status"] = "unavailable"
            if not entry.get("first_unavailable"):
                entry["first_unavailable"] = today

        models[slug] = entry

    # prune slugs no longer in config
    config_slugs = {d.model_slug for d in deployments}
    for slug in list(models.keys()):
        if slug not in config_slugs:
            del models[slug]

    return state


# ── removal logic ────────────────────────────────────────────────────────────

def identify_removals(
    state: dict,
    deployments: list[Deployment],
) -> tuple[list[Deployment], list[tuple[Deployment, int]]]:
    """Return (removals, warnings).

    removals: deployments to remove from config.yaml
    warnings: (deployment, days_unavailable) — should warn but not remove
    """
    today = date.today()
    models = state.get("models", {})

    # group deployments by model_name
    groups: dict[str, list[Deployment]] = {}
    for dep in deployments:
        groups.setdefault(dep.model_name, []).append(dep)

    removals: list[Deployment] = []
    warnings: list[tuple[Deployment, int]] = []

    for dep in deployments:
        entry = models.get(dep.model_slug, {})
        first_fail = entry.get("first_unavailable")
        if not first_fail:
            continue

        days = (today - date.fromisoformat(first_fail)).days
        if days < STALE_DAYS:
            if entry.get("status") == "unavailable":
                warnings.append((dep, days))
            continue

        # candidate for removal
        if dep.model_name in PROTECTED_NAMES:
            continue

        group = groups[dep.model_name]
        # count how many alive deployments remain in this group (excluding this one)
        alive_in_group = sum(
            1 for d in group
            if d.model_slug != dep.model_slug
            and models.get(d.model_slug, {}).get("status") != "unavailable"
        )
        # also count how many are already scheduled for removal
        already_removing = sum(1 for r in removals if r.model_name == dep.model_name)
        remaining = len(group) - already_removing - 1

        if remaining < 1 or alive_in_group < 1:
            # would empty the group — warn instead
            warnings.append((dep, days))
            continue

        removals.append(dep)

    return removals, warnings


def remove_from_config(config_text: str, removals: list[Deployment]) -> str:
    """Remove deployment blocks from config.yaml text. Works bottom-to-top."""
    lines = config_text.splitlines(keepends=True)
    # sort by comment_start descending to remove from bottom first
    for dep in sorted(removals, key=lambda d: d.comment_start, reverse=True):
        start = dep.comment_start - 1  # 0-indexed
        end = dep.end_line  # 1-indexed → exclusive in 0-indexed
        del lines[start:end]
    return "".join(lines)


# ── discovery ────────────────────────────────────────────────────────────────

def discover_new_openrouter(
    catalog: set[str] | None,
    deployments: list[Deployment],
    raw_openrouter: set[str] | None,
) -> list[str]:
    """Return OpenRouter :free model IDs not in config (original casing)."""
    if raw_openrouter is None:
        return []
    configured = set()
    for dep in deployments:
        if dep.provider == "openrouter":
            configured.add(normalize_slug(dep).lower())
    return sorted(
        mid for mid in raw_openrouter
        if mid.endswith(":free") and mid.lower() not in configured
    )


# ── report ───────────────────────────────────────────────────────────────────

def print_report(
    deployments: list[Deployment],
    check_results: dict[str, str],
    catalogs: dict[str, set[str] | None],
    removals: list[Deployment],
    warnings: list[tuple[Deployment, int]],
    discoveries: list[str],
    dry_run: bool,
) -> None:
    providers_ok = [p for p, c in catalogs.items() if c is not None]
    providers_fail = [p for p, c in catalogs.items() if c is None and p not in ("zai", "unknown")]

    n_total = len({d.model_slug for d in deployments})
    n_ok = sum(1 for s in check_results.values() if s == "available")
    n_assumed = sum(1 for s in check_results.values() if s == "assumed_ok")
    n_unavail = sum(1 for s in check_results.values() if s == "unavailable")

    print(f"\n  {BOLD}Providers:{NC} {', '.join(providers_ok)}", end="")
    if providers_fail:
        print(f"  {YELLOW}(unreachable: {', '.join(providers_fail)}){NC}", end="")
    print()

    # per-slug status
    removal_slugs = {d.model_slug for d in removals}
    warning_map = {d.model_slug: days for d, days in warnings}
    seen: set[str] = set()

    for dep in deployments:
        if dep.model_slug in seen:
            continue
        seen.add(dep.model_slug)
        status = check_results.get(dep.model_slug, "unknown")
        canonical = normalize_slug(dep)

        if dep.model_slug in removal_slugs:
            prefix = f"{RED}  \u2717"
            days = ""
            entry_days = warning_map.get(dep.model_slug)
            if entry_days is None:
                # get from state
                pass
            suffix = f"— REMOVING (dead >{STALE_DAYS}d){NC}"
            if dry_run:
                suffix = f"— would remove (dead >{STALE_DAYS}d){NC}"
            print(f"{prefix} {dep.model_name} ({dep.provider}) {canonical} {suffix}")
        elif dep.model_slug in warning_map:
            days = warning_map[dep.model_slug]
            print(f"{YELLOW}  \u26a0 {dep.model_name} ({dep.provider}) {canonical} — unavailable ({days}d){NC}")
        elif status == "available":
            print(f"{GREEN}  \u2713 {dep.model_name} ({dep.provider}) {canonical}{NC}")
        elif status == "assumed_ok":
            print(f"{DIM}  ~ {dep.model_name} ({dep.provider}) {canonical} — assumed ok{NC}")
        else:
            print(f"{YELLOW}  ? {dep.model_name} ({dep.provider}) {canonical}{NC}")

    # summary line
    parts = [f"{n_ok} ok"]
    if n_assumed:
        parts.append(f"{n_assumed} assumed")
    if n_unavail:
        parts.append(f"{YELLOW}{n_unavail} unavailable{NC}")
    if removals:
        verb = "would remove" if dry_run else "removed"
        parts.append(f"{RED}{len(removals)} {verb}{NC}")
    print(f"\n  {BOLD}{n_total} models checked:{NC} {', '.join(parts)}")

    if removals and not dry_run:
        print(f"  {YELLOW}config.yaml updated — restarting LiteLLM...{NC}")

    # discoveries
    if discoveries:
        print(f"\n  {CYAN}{BOLD}New free models on OpenRouter ({len(discoveries)} total):{NC}")
        for mid in discoveries[:5]:
            print(f"{CYAN}    + {mid}{NC}")
        if len(discoveries) > 5:
            print(f"{DIM}    ... and {len(discoveries) - 5} more (run with --discover){NC}")


# ── main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    dry_run = "--dry-run" in sys.argv
    show_all_discoveries = "--discover" in sys.argv

    if not CONFIG_PATH.is_file():
        print(f"{RED}check-models: config.yaml not found at {CONFIG_PATH}{NC}", file=sys.stderr)
        return 1

    config_text = CONFIG_PATH.read_text("utf-8")
    deployments = parse_deployments(config_text)
    if not deployments:
        print(f"{RED}check-models: no deployments parsed from config.yaml{NC}", file=sys.stderr)
        return 1

    # fetch provider catalogs (lowercased for matching)
    raw_openrouter = fetch_openrouter_models()  # keep original casing for discovery
    catalogs = fetch_all_catalogs(raw_openrouter)

    # check each deployment
    check_results = check_deployments(deployments, catalogs)

    # update state
    state = load_state()
    state = update_state(state, check_results, deployments)

    # identify removals
    removals, warnings = identify_removals(state, deployments)

    # discover new OpenRouter free models (uses raw catalog for original casing)
    discoveries = discover_new_openrouter(catalogs.get("openrouter"), deployments, raw_openrouter)
    if not show_all_discoveries:
        display_discoveries = discoveries[:5]
    else:
        display_discoveries = discoveries

    # apply removals
    config_changed = False
    if removals and not dry_run:
        new_config = remove_from_config(config_text, removals)
        backup = CONFIG_PATH.read_bytes()
        CONFIG_PATH.write_text(new_config, "utf-8")

        # safety gate: verify-free-only reads config.yaml from its hardcoded path
        if VERIFY_SCRIPT.is_file():
            result = subprocess.run(
                [str(VERIFY_SCRIPT)],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                CONFIG_PATH.write_bytes(backup)
                print(f"{RED}check-models: verify-free-only failed after removal — reverted{NC}", file=sys.stderr)
                print(result.stderr, file=sys.stderr)
                # state keeps unavailability dates so next run retries removal
                removals = []
            else:
                config_changed = True
        else:
            config_changed = True

    # save state
    save_state(state)

    # report
    print_report(
        deployments, check_results, catalogs,
        removals, warnings,
        display_discoveries if discoveries else [],
        dry_run,
    )

    # show all discoveries if requested
    if show_all_discoveries and len(discoveries) > 5:
        print(f"\n  {CYAN}{BOLD}All new free models on OpenRouter:{NC}")
        for mid in discoveries:
            print(f"{CYAN}    + {mid}{NC}")

    # restart LiteLLM if config changed
    if config_changed:
        subprocess.run(
            ["docker", "compose", "--project-directory", str(COMPOSE_DIR), "restart"],
            capture_output=True,
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
