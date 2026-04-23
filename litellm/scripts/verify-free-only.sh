#!/usr/bin/env python3
"""verify-free-only — hard safety rail against accidental paid model use.

Walks every deployment in config.yaml and verifies its (model, api_base) pair
points at a free-tier upstream. Whitelist:

  OpenRouter (https://openrouter.ai/api/v1)        — model must end with `:free`
  Groq native (model starts with `groq/`)          — free tier built in
  Z.AI native (model starts with `zai/`)           — free tier
  Gemini native (model starts with `gemini/`)      — free tier (AI Studio)
  Mistral native (model starts with `mistral/`)    — free tier (~1B tokens/month)
  Cerebras (https://api.cerebras.ai/v1)            — free tier (1M tokens/day)
  NVIDIA NIM (https://integrate.api.nvidia.com/v1) — free credits
  GitHub Models (https://models.github.ai/inference) — free quota

Anything else exits non-zero.

Run manually before any config change, or wire into a pre-commit hook:
    ~/projects/dotfiles/litellm/scripts/verify-free-only.sh
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


FREE_API_BASES = {
    "https://integrate.api.nvidia.com/v1",
    "https://models.github.ai/inference",
    "https://api.cerebras.ai/v1",
}
OPENROUTER_API_BASE = "https://openrouter.ai/api/v1"


def parse_deployments(yaml_text: str) -> list[tuple[int, int, str | None, str | None]]:
    """Return [(deployment_index, line_number, model, api_base), ...].

    Simple line-oriented parse — the YAML structure is stable and nesting is
    at most two levels inside `model_list`. Avoids a PyYAML dependency so the
    gate works on any Python 3.
    """
    deployments: list[tuple[int, int, str | None, str | None]] = []
    in_model_list = False
    current: dict[str, object] = {"model": None, "api_base": None, "line": 0}
    idx = 0

    def commit():
        if current["model"] is not None:
            deployments.append((idx, int(current["line"]), current["model"], current["api_base"]))  # type: ignore[arg-type]

    for lineno, raw in enumerate(yaml_text.splitlines(), start=1):
        line = raw.rstrip("\n")

        if line.startswith("model_list:"):
            in_model_list = True
            continue

        if in_model_list and re.match(r"^[A-Za-z_]+:", line):
            in_model_list = False

        if not in_model_list:
            continue

        m = re.match(r"^  - model_name:\s*(.*)$", line)
        if m:
            commit()
            idx += 1
            current = {"model": None, "api_base": None, "line": lineno}
            continue

        m = re.match(r"^      model:\s*(.*)$", line)
        if m and current["model"] is None:
            current["model"] = m.group(1).strip().strip('"').strip("'")
            continue

        m = re.match(r"^      api_base:\s*(.*)$", line)
        if m:
            current["api_base"] = m.group(1).strip().strip('"').strip("'")
            continue

    commit()
    return deployments


def classify(model: str, api_base: str | None) -> tuple[bool, str]:
    """Return (is_free, reason)."""
    if model.startswith("groq/"):
        return True, "groq native"
    if model.startswith("zai/"):
        return True, "zai native (free tier)"
    if model.startswith("gemini/"):
        return True, "gemini native (AI Studio free tier)"
    if model.startswith("mistral/"):
        return True, "mistral native (free tier)"
    if api_base == OPENROUTER_API_BASE:
        if model.endswith(":free"):
            return True, "openrouter :free"
        return False, f"OpenRouter slug missing :free suffix ({model!r})"
    if api_base in FREE_API_BASES:
        return True, f"whitelisted api_base ({api_base})"
    if api_base is None:
        return False, "non-groq deployment has no api_base (unknown provider)"
    return False, f"unknown/paid api_base: {api_base}"


def main() -> int:
    config_path = Path(__file__).resolve().parent.parent / "config.yaml"
    if not config_path.is_file():
        print(f"verify-free-only: config.yaml not found at {config_path}", file=sys.stderr)
        return 2

    deployments = parse_deployments(config_path.read_text(encoding="utf-8"))
    if not deployments:
        print("verify-free-only: no deployments parsed from config.yaml", file=sys.stderr)
        return 3

    violations = []
    for idx, line, model, api_base in deployments:
        ok, reason = classify(model, api_base)
        if not ok:
            violations.append((idx, line, model, api_base, reason))

    if violations:
        for idx, line, model, api_base, reason in violations:
            base_repr = api_base or "(no api_base)"
            print(f"  \u2717 deployment[{idx}] (config.yaml:{line})  {model}  @ {base_repr}  \u2014 {reason}", file=sys.stderr)
        print(
            f"\nverify-free-only: FAILED \u2014 {len(violations)} of {len(deployments)} deployment(s) not free-tier.",
            file=sys.stderr,
        )
        print("Either switch to a free upstream or remove the deployment.", file=sys.stderr)
        return 1

    print(f"verify-free-only: OK \u2014 all {len(deployments)} deployments use free-tier upstreams.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
