"""Manipulators that can never run, found by simulating Karabiner's first-match rule.

Karabiner takes the first manipulator, in rule-file order, whose `from` key, modifiers
and conditions all match. For every `from` key this tries every combination of the nine
modifiers and of the conditions the rules read; a manipulator that wins none of them is
dead — an earlier one always takes its chord.
"""
import itertools
import json

MODIFIERS = ("left_shift", "left_control", "left_option", "left_command",
             "right_shift", "right_control", "right_option", "right_command", "fn")
_STATES = [frozenset(m for m, on in zip(MODIFIERS, bits) if on)
           for bits in itertools.product((False, True), repeat=len(MODIFIERS))]


def _flat(rules):
    """[(rule name, index in the rule, manipulator)] from [(name, rule document)], in order."""
    return [(name, i, m) for name, rule in rules for i, m in enumerate(rule["manipulators"])]


def _key(m):
    return json.dumps({k: v for k, v in m["from"].items() if k != "modifiers"}, sort_keys=True)


def _atom(condition):
    return json.dumps({k: v for k, v in condition.items() if k != "type"}, sort_keys=True)


def _conditions_hold(m, env):
    return all(env[_atom(c)] == c["type"].endswith("_if") for c in m.get("conditions", []))


def _modifiers_match(m, state):
    mods = m["from"].get("modifiers", {})
    mandatory, optional = set(mods.get("mandatory", [])), set(mods.get("optional", []))
    unknown = (mandatory | optional) - set(MODIFIERS) - {"any"}
    if unknown:
        raise ValueError(f"shadow: modifiers {sorted(unknown)} are not simulated")
    return mandatory <= state and ("any" in optional or state - mandatory <= optional)


def winners(manips):
    """{(from key, modifier state, condition values): index of the manipulator that runs}."""
    by_key = {}
    for n, (_, _, m) in enumerate(manips):
        by_key.setdefault(_key(m), []).append(n)
    out = {}
    for key, idx in by_key.items():
        atoms = sorted({_atom(c) for n in idx for c in manips[n][2].get("conditions", [])})
        for values in itertools.product((False, True), repeat=len(atoms)):
            env = dict(zip(atoms, values))
            live = [n for n in idx if _conditions_hold(manips[n][2], env)]
            for state in _STATES:
                hit = next((n for n in live if _modifiers_match(manips[n][2], state)), None)
                if hit is not None:
                    out[(key, state, values)] = hit
    return out


def dead(rules):
    """[(rule, index, manipulator, "rule#index" of the one that takes its exact chord)] for [(name, rule document)]."""
    manips = _flat(rules)
    won = winners(manips)
    alive = set(won.values())
    out = []
    for n, (name, i, m) in enumerate(manips):
        if n in alive:
            continue
        exact = frozenset(m["from"].get("modifiers", {}).get("mandatory", []))
        takers = {won[k] for k in won if k[0] == _key(m) and k[1] == exact}
        by = ", ".join(sorted(f"{manips[t][0]}#{manips[t][1] + 1}" for t in takers))
        out.append((name, i, m, by))
    return out


def describe(name, i, m, by):
    mods = "+".join(sorted(m["from"].get("modifiers", {}).get("mandatory", [])))
    key = m["from"].get("key_code") or _key(m)
    return f"{name}#{i + 1} ({mods + '+' if mods else ''}{key}) never fires: {by or 'an earlier rule'} takes it first"
