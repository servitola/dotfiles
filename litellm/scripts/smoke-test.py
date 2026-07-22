#!/usr/bin/env python3
"""smoke-test — prove every model in config.yaml actually ANSWERS.

Companion to check-models.py, which is a *catalog* check: it asks each provider
"is this slug in your /v1/models list?".  That is necessary but nowhere near
sufficient.  Measured on 2026-07-22, the catalog check reported a healthy config
while, live:

  * NVIDIA listed `moonshotai/kimi-k2.6` and 404'd every call to it
  * OpenRouter listed nothing wrong, but the key's spend cap was exhausted
    so all 30 `:free` deployments 429'd
  * Chutes 402'd on every call (account balance $0.00)
  * Together had no API key passed into the container at all
  * `embed` 400'd on every request, so RAG could not re-embed

None of that is visible from a catalog.  This script calls the models.

THREE THINGS THIS GETS RIGHT THAT A NAIVE PROBE DOES NOT
--------------------------------------------------------
1. **It defeats the response cache.**  Every request carries
   `{"cache": {"no-cache": true}}`.  Without it a sweep measures Redis, not the
   providers: the first naive run of this sweep reported 53/65 aliases "OK" in
   ~0.2s each — all cache hits.  The true number was 39/65.  (The cache was also
   leaking answers ACROSS models at the time; that is fixed in config.yaml now,
   but `no-cache` remains mandatory here regardless.)

2. **It is reasoning-model aware.**  A probe with `max_tokens: 16` gets an empty
   `content` from any thinking model — the budget is consumed by reasoning
   tokens and `finish_reason` comes back `length`.  Twelve models looked broken
   for exactly this reason.  We send a generous budget and treat
   "empty content + reasoning_content present + finish_reason=length" as
   INCONCLUSIVE, never as a failure.

3. **It separates "dead" from "rate-limited".**  A free-tier pool 429s
   constantly; that is the normal steady state, not a fault.  Auto-removing a
   deployment because it was busy would be destructive.  Failures are classified
   (see classify()) and only PERMANENT ones are ever proposed for removal.

LAYERS
------
  L1  per-DEPLOYMENT liveness  — GET /health (LiteLLM's own prober; it is
      mode-aware, so embedding/TTS/STT deployments get the right endpoint
      instead of a bogus chat call).  ~60s for the whole config.
  L2  per-ALIAS functional     — a real request per model_name through the
      proxy, which is what a caller actually experiences: routing, retries,
      fallbacks and response shape all included.
  L3  group coverage gate      — rotation groups (coding/reasoning/fast/…) are
      shuffled across N deployments; N-1 of them can rot without any single
      request failing.  This is the check that catches `coding` decaying to
      8/18 live members.

Usage:
    python3 smoke-test.py                 # L1 + L2 + L3, human report
    python3 smoke-test.py --quick         # L2 + L3 only (skips the 60s /health)
    python3 smoke-test.py --alias coding  # probe one alias
    python3 smoke-test.py --json          # machine-readable, for cron/alerting

Exit codes:  0 all good · 1 problems found (see report) · 2 proxy unreachable
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR.parent / "config.yaml"
STATE_PATH = SCRIPT_DIR.parent / "model-health.json"

PROXY = os.environ.get("LITELLM_BASE_URL", "http://localhost:4000")
KEY = os.environ.get("LITELLM_MASTER_KEY", "sk-local-workbot")

# A factual question with a single unambiguous one-word answer. Deliberately
# nonce-tagged so it cannot collide with a real cached conversation, and chosen
# so that a wrong answer means the model is broken/substituted rather than just
# opinionated.
PROBE_Q = "What is the capital city of Japan? Reply with the city name only."
PROBE_EXPECT = "tokyo"

# Big enough that a reasoning model still has budget left for visible content
# after its thinking tokens. See docstring point 2.
PROBE_MAX_TOKENS = 800

# Aliases that cannot be probed automatically, with the reason.
UNPROBEABLE = {
    "voiceink-local": "audio_transcription — needs a real audio file upload",
}

# Rotation groups: shuffled pools where a dead member is invisible per-request.
# floor = minimum fraction of members that must be live before we fail the gate.
GROUP_FLOORS = {
    "coding": 0.6,
    "reasoning": 0.6,
    "fast": 0.6,
    "vision": 0.5,
    "uncensored": 0.5,
    "web-search": 0.5,
}

# ── failure classification ───────────────────────────────────────────────────
# Adapted from Bifrost's per-key error taxonomy: permanent-vs-transient matters
# far more than the raw status code, because only PERMANENT justifies touching
# config.yaml.

PERMANENT = "permanent"    # dead slug / dead key / needs payment → propose removal
QUOTA = "quota"            # 429 / daily cap → expected here, never auto-remove
TRANSIENT = "transient"    # 5xx / timeout → retry later, flag if it persists
INCONCLUSIVE = "inconclusive"
OK = "ok"

_PERMANENT_PATTERNS = (
    "unavailable for free",
    "does not exist or you do not have access",
    "api_key client option must be set",
    "payment method is required",
    "quota exceeded and account balance",
    "no longer supported",
    "model_not_found",
    "invalid api key",
    "incorrect api key",
    "not found for account",   # NVIDIA: listed in catalog, unroutable for us
)


def classify(status: int | None, body: str) -> str:
    """Map an upstream failure onto {permanent, quota, transient}.

    Text is checked BEFORE status code on purpose: providers are wildly
    inconsistent about codes (Chutes returns 402 for an empty balance, SambaNova
    402 for "add a payment method", OpenRouter 404 for "no longer free") but the
    message is usually unambiguous.
    """
    low = body.lower()
    for pat in _PERMANENT_PATTERNS:
        if pat in low:
            return PERMANENT
    if "rate limit" in low or "ratelimiterror" in low or "exceeded your current quota" in low:
        return QUOTA
    if status == 429:
        return QUOTA
    if status in (401, 402, 403, 404):
        return PERMANENT
    if status is not None and status >= 500:
        return TRANSIENT
    if "timeout" in low or "timed out" in low:
        return TRANSIENT
    if status == 400:
        # A 400 that isn't one of the permanent messages above is usually a
        # param-compatibility problem (the `encoding_format` class of bug) —
        # real, actionable, and not self-healing.
        return PERMANENT
    return TRANSIENT


# ── http ─────────────────────────────────────────────────────────────────────

def _post(path: str, payload: dict, timeout: int = 120) -> tuple[int | None, bytes, float]:
    req = urllib.request.Request(
        f"{PROXY}{path}",
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"},
    )
    t0 = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read(), time.monotonic() - t0
    except urllib.error.HTTPError as e:
        return e.code, e.read(), time.monotonic() - t0
    except Exception as e:  # noqa: BLE001 — connection errors, timeouts, DNS…
        return None, str(e).encode(), time.monotonic() - t0


def _err_text(raw: bytes) -> str:
    try:
        d = json.loads(raw)
        msg = d.get("error", {}).get("message") if isinstance(d, dict) else None
        return (msg or json.dumps(d))[:400]
    except Exception:  # noqa: BLE001
        return raw.decode("utf-8", "replace")[:400]


# ── config ───────────────────────────────────────────────────────────────────

def load_config() -> dict:
    """Parse config.yaml. Prefers PyYAML, falls back to a line parser.

    The fallback exists because this script is run from cron on a machine where
    the system python may not have PyYAML, and a health check that cannot run is
    worse than one that is slightly less precise.
    """
    text = CONFIG_PATH.read_text("utf-8")
    try:
        import yaml  # noqa: PLC0415
        cfg = yaml.safe_load(text)
        out = []
        for m in cfg.get("model_list", []):
            p = m.get("litellm_params", {})
            out.append({
                "alias": m.get("model_name"),
                "model": p.get("model"),
                "api_base": p.get("api_base"),
                "mode": (m.get("model_info") or {}).get("mode", "chat"),
            })
        return {"deployments": out, "router": cfg.get("router_settings", {})}
    except ImportError:
        out, cur = [], None
        for line in text.splitlines():
            m = re.match(r"^  - model_name:\s*(\S+)", line)
            if m:
                if cur:
                    out.append(cur)
                cur = {"alias": m.group(1), "model": None, "api_base": None, "mode": "chat"}
            elif cur is not None:
                for k in ("model", "api_base", "mode"):
                    mm = re.match(rf"^\s+{k}:\s*(\S+)\s*$", line)
                    if mm:
                        cur[k] = mm.group(1)
        if cur:
            out.append(cur)
        return {"deployments": out, "router": {}}


# ── L1: per-deployment liveness via LiteLLM's own /health ────────────────────

def layer1_health(timeout: int = 300) -> dict | None:
    """GET /health — LiteLLM probes every deployment with the right endpoint.

    Returns {(model, api_base): (state, detail)} or None if unreachable.
    We use LiteLLM's prober rather than rolling our own per-deployment calls
    because there is no supported way to address one specific deployment of a
    shuffled model_name from outside, and because /health already honours each
    deployment's `model_info.mode` (embedding vs audio_speech vs chat).
    """
    req = urllib.request.Request(
        f"{PROXY}/health", headers={"Authorization": f"Bearer {KEY}"}
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = json.loads(r.read())
    except Exception as e:  # noqa: BLE001
        print(f"  !! /health failed: {e}", file=sys.stderr)
        return None

    out: dict[tuple, tuple[str, str]] = {}
    for e in data.get("healthy_endpoints", []):
        out[(e.get("model"), e.get("api_base"))] = (OK, "")
    for e in data.get("unhealthy_endpoints", []):
        detail = str(e.get("error", ""))[:400]
        out[(e.get("model"), e.get("api_base"))] = (classify(None, detail), detail)
    return out


# ── L2: per-alias functional probe ───────────────────────────────────────────

def probe_alias(alias: str, mode: str) -> dict:
    """One real request through the proxy — the caller's-eye view."""
    if alias in UNPROBEABLE:
        return {"alias": alias, "state": INCONCLUSIVE, "detail": UNPROBEABLE[alias], "secs": 0.0}

    if mode == "embedding":
        st, raw, secs = _post("/v1/embeddings",
                              {"model": alias, "input": f"smoke probe {int(time.time())}"})
        if st == 200:
            try:
                dim = len(json.loads(raw)["data"][0]["embedding"])
                return {"alias": alias, "state": OK, "detail": f"dim={dim}", "secs": secs,
                        "dim": dim}
            except Exception as e:  # noqa: BLE001
                return {"alias": alias, "state": PERMANENT,
                        "detail": f"malformed embedding response: {e}", "secs": secs}
        body = _err_text(raw)
        return {"alias": alias, "state": classify(st, body), "detail": body, "secs": secs}

    if mode == "audio_speech":
        st, raw, secs = _post("/v1/audio/speech",
                              {"model": alias, "input": "проверка связи", "voice": "alloy"})
        if st == 200 and len(raw) > 1000:
            return {"alias": alias, "state": OK, "detail": f"{len(raw)}B audio", "secs": secs}
        body = _err_text(raw)
        if st == 200:
            return {"alias": alias, "state": PERMANENT,
                    "detail": f"suspiciously small audio ({len(raw)}B)", "secs": secs}
        return {"alias": alias, "state": classify(st, body), "detail": body, "secs": secs}

    if mode in ("image_generation",):
        return {"alias": alias, "state": INCONCLUSIVE,
                "detail": "image_generation — not auto-probed", "secs": 0.0}

    # chat
    st, raw, secs = _post("/v1/chat/completions", {
        "model": alias,
        "messages": [{"role": "user", "content": PROBE_Q}],
        "max_tokens": PROBE_MAX_TOKENS,
        "temperature": 0,
        "cache": {"no-cache": True},   # see docstring point 1 — non-negotiable
    })
    if st != 200:
        body = _err_text(raw)
        return {"alias": alias, "state": classify(st, body), "detail": body, "secs": secs}

    try:
        d = json.loads(raw)
        ch = d["choices"][0]
        msg = ch.get("message", {})
        content = (msg.get("content") or "").strip()
        finish = ch.get("finish_reason")
    except Exception as e:  # noqa: BLE001
        return {"alias": alias, "state": PERMANENT,
                "detail": f"malformed chat response: {e}", "secs": secs}

    if not content:
        # Reasoning model that spent its whole budget thinking — not a failure.
        if msg.get("reasoning_content") or finish == "length":
            return {"alias": alias, "state": INCONCLUSIVE,
                    "detail": f"no visible content (finish={finish}, reasoning-only)",
                    "secs": secs}
        return {"alias": alias, "state": PERMANENT,
                "detail": f"empty content, finish={finish}", "secs": secs}

    correct = PROBE_EXPECT in content.lower()
    return {
        "alias": alias,
        # Answering the wrong thing is a real signal (wrong model wired up, or a
        # cache/routing bug) but it is NOT an availability failure — the model
        # responded. Surface it separately rather than calling it dead.
        "state": OK if correct else INCONCLUSIVE,
        "detail": content[:60].replace("\n", " ") + ("" if correct else "  <- unexpected answer"),
        "secs": secs,
    }


# ── L3: group coverage ───────────────────────────────────────────────────────

def layer3_groups(deployments: list[dict], health: dict | None) -> list[dict]:
    """How much of each shuffled rotation group is actually alive."""
    if health is None:
        return []
    groups: dict[str, list[dict]] = {}
    for d in deployments:
        groups.setdefault(d["alias"], []).append(d)

    rows = []
    for alias, members in groups.items():
        if len(members) < 2 and alias not in GROUP_FLOORS:
            continue  # single-deployment direct alias — L2 already covers it
        live, dead = 0, []
        rotted = 0   # PERMANENT only — needs a config edit
        for m in members:
            state, detail = health.get((m["model"], m["api_base"]), (None, ""))
            if state == OK:
                live += 1
            elif state is not None:
                dead.append((m["model"], state))
                if state == PERMANENT:
                    rotted += 1
        floor = GROUP_FLOORS.get(alias)
        frac = live / len(members) if members else 0
        # Deliberately do NOT fail the gate on quota-blocked members. On a
        # free-tier pool every provider is quota-capped, so daily 429s are the
        # normal state and a gate that fires on them is noise a human learns to
        # ignore — which is exactly how `coding` was allowed to rot to 8/18.
        # Fail only on things a human must ACT on:
        #   * a permanently dead member (dead slug / dead key / needs payment)
        #   * a group with nothing left serving at all
        # `frac`/`floor` are still reported, as a trend to watch.
        rows.append({
            "group": alias, "live": live, "total": len(members),
            "frac": frac, "floor": floor, "rotted": rotted,
            "failing": rotted > 0 or live == 0,
            "under_floor": floor is not None and frac < floor,
            "dead": dead,
        })
    return sorted(rows, key=lambda r: (not r["failing"], r["frac"]))


# ── report ───────────────────────────────────────────────────────────────────

C = {"g": "\033[32m", "r": "\033[31m", "y": "\033[33m", "b": "\033[34m",
     "d": "\033[2m", "0": "\033[0m"}
if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
    C = dict.fromkeys(C, "")

_STATE_COLOR = {OK: "g", PERMANENT: "r", QUOTA: "y", TRANSIENT: "y", INCONCLUSIVE: "d"}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--quick", action="store_true",
                    help="skip the ~60s /health sweep (L2+L3 only)")
    ap.add_argument("--alias", help="probe a single alias")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--jobs", type=int, default=8, help="probe concurrency (default 8)")
    ap.add_argument("--no-write", action="store_true",
                    help="don't update model-health.json")
    args = ap.parse_args()

    # Fail fast and loudly if the proxy is down — per repo convention, consumers
    # should not silently degrade.
    try:
        urllib.request.urlopen(f"{PROXY}/health/liveliness", timeout=5).read()
    except Exception as e:  # noqa: BLE001
        print(f"smoke-test: proxy unreachable at {PROXY} ({e})", file=sys.stderr)
        return 2

    cfg = load_config()
    deployments = cfg["deployments"]

    modes: dict[str, str] = {}
    for d in deployments:
        modes.setdefault(d["alias"], d["mode"] or "chat")
    aliases = [args.alias] if args.alias else list(modes)
    if args.alias and args.alias not in modes:
        print(f"smoke-test: unknown alias {args.alias!r}", file=sys.stderr)
        return 2

    health = None
    if not args.quick and not args.alias:
        if not args.json:
            print(f"{C['b']}L1  per-deployment liveness (GET /health, ~60s)…{C['0']}")
        health = layer1_health()

    if not args.json:
        print(f"{C['b']}L2  per-alias functional probe ({len(aliases)} aliases, "
              f"cache bypassed)…{C['0']}")
    with ThreadPoolExecutor(args.jobs) as ex:
        results = list(ex.map(lambda a: probe_alias(a, modes[a]), aliases))

    groups = layer3_groups(deployments, health)

    by_state: dict[str, list[dict]] = {}
    for r in results:
        by_state.setdefault(r["state"], []).append(r)

    broken = by_state.get(PERMANENT, [])
    quota = by_state.get(QUOTA, [])
    failing_groups = [g for g in groups if g["failing"]]

    if args.json:
        print(json.dumps({
            "ts": datetime.now().isoformat(timespec="seconds"),
            "aliases": results, "groups": groups,
            "summary": {
                "ok": len(by_state.get(OK, [])), "permanent": len(broken),
                "quota": len(quota), "transient": len(by_state.get(TRANSIENT, [])),
                "inconclusive": len(by_state.get(INCONCLUSIVE, [])),
                "failing_groups": [g["group"] for g in failing_groups],
            },
        }, indent=2, ensure_ascii=False))
    else:
        print()
        for state in (OK, INCONCLUSIVE, QUOTA, TRANSIENT, PERMANENT):
            rows = by_state.get(state, [])
            if not rows:
                continue
            c = C[_STATE_COLOR[state]]
            print(f"{c}── {state.upper()}  ({len(rows)}){C['0']}")
            for r in sorted(rows, key=lambda x: x["alias"]):
                print(f"   {r['secs']:6.1f}s  {r['alias']:<24} {C['d']}{r['detail'][:96]}{C['0']}")
            print()

        if groups:
            print(f"{C['b']}── ROTATION GROUP COVERAGE{C['0']}")
            for g in groups:
                if g["failing"]:
                    mark = f"{C['r']}FAIL{C['0']}"
                elif g["under_floor"]:
                    mark = f"{C['y']}thin{C['0']}"   # quota-thinned, self-heals
                else:
                    mark = f"{C['g']} ok {C['0']}"
                floor = f"floor {g['floor']:.0%}" if g["floor"] else "no floor"
                print(f"   {mark}  {g['group']:<16} {g['live']:>2}/{g['total']:<3} "
                      f"({g['frac']:.0%}, {floor})"
                      + (f"  {C['r']}{g['rotted']} PERMANENTLY dead{C['0']}"
                         if g["rotted"] else ""))
                for slug, st in g["dead"]:
                    print(f"          {C['d']}dead[{st}] {slug}{C['0']}")
            print()

        print(f"{C['b']}── SUMMARY{C['0']}")
        print(f"   aliases  {len(by_state.get(OK, []))} ok · {len(broken)} broken · "
              f"{len(quota)} rate-limited · "
              f"{len(by_state.get(TRANSIENT, []))} transient · "
              f"{len(by_state.get(INCONCLUSIVE, []))} inconclusive")
        if health is not None:
            live = sum(1 for v in health.values() if v[0] == OK)
            print(f"   deployments  {live}/{len(health)} live")
        if broken:
            print(f"\n{C['r']}   Broken aliases need a config.yaml change — they will NOT "
                  f"self-heal:{C['0']}")
            for r in broken:
                print(f"     {r['alias']}: {r['detail'][:110]}")
        if quota:
            print(f"\n{C['y']}   Rate-limited = quota exhausted, not dead. Expected on free "
                  f"tiers; re-run later.{C['0']}")

    if not args.no_write and not args.alias:
        try:
            state = json.loads(STATE_PATH.read_text("utf-8")) if STATE_PATH.is_file() else {}
        except Exception:  # noqa: BLE001
            state = {}
        # Written under its own key so check-models.py's catalog data in
        # `models` stays intact — the two checks are complementary.
        state["smoke"] = {
            "last_run": datetime.now().isoformat(timespec="seconds"),
            "aliases": {r["alias"]: {"state": r["state"], "detail": r["detail"][:200]}
                        for r in results},
            "groups": {g["group"]: {"live": g["live"], "total": g["total"]} for g in groups},
        }
        tmp = STATE_PATH.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n", "utf-8")
        tmp.rename(STATE_PATH)

    return 1 if (broken or failing_groups) else 0


if __name__ == "__main__":
    sys.exit(main())
