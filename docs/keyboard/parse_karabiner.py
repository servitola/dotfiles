"""Parse Karabiner rule JSON files to build complete remapping table."""
import generator_path  # noqa: F401
import layers
from keys import CONSUMER_SYM as _CONSUMER_SYM, HYPER as _HYPER, KEY_SYM as _KEY_SYM, TO_PHYS as _TO_PHYS

_MOD_SYM = {"shift":"⇧", "left_shift":"⇧", "right_shift":"⇧",
    "control":"⌃", "left_control":"⌃", "right_control":"⌃",
    "option":"⌥", "left_option":"⌥", "right_option":"⌥",
    "command":"⌘", "left_command":"⌘", "right_command":"⌘"}

# Map Karabiner modifier names → our layer modifier names
_TO_LAYER_MOD = {
    "left_shift":"shift", "right_shift":"shift", "shift":"shift",
    "left_control":"ctrl", "right_control":"ctrl", "control":"ctrl",
    "left_option":"alt", "right_option":"alt", "option":"alt",
    "left_command":"cmd", "right_command":"cmd", "command":"cmd",
    "fn":"fn",
}


def _from_mods_to_layer(mandatory):
    """Convert Karabiner mandatory modifiers to our layer frozenset."""
    mods = set()
    remaining = set(mandatory)
    if _HYPER.issubset(remaining):
        mods.add("hyper")
        remaining -= _HYPER
    for m in remaining:
        lm = _TO_LAYER_MOD.get(m)
        if lm: mods.add(lm)
    return frozenset(mods)


def _to_display(to_entry):
    """Convert a Karabiner 'to' entry to a display string."""
    if not to_entry: return ""
    # Consumer key (media/brightness)
    ck = to_entry.get("consumer_key_code", "")
    if ck: return _CONSUMER_SYM.get(ck, ck)
    # Shell command
    if to_entry.get("shell_command"): return "⌨ script"
    # Regular key
    kc = to_entry.get("key_code", "")
    if not kc: return ""
    # Check if key_code is actually a system function (illumination, brightness, etc.)
    if kc in _CONSUMER_SYM: return _CONSUMER_SYM[kc]
    sym = _KEY_SYM.get(kc, kc.upper() if kc.startswith("f") and kc[1:].isdigit() else kc)
    # Add modifier symbols
    tm = to_entry.get("modifiers", [])
    if isinstance(tm, dict): tm = tm.get("mandatory", [])
    glyphs = {_MOD_SYM.get(m, "") for m in tm}
    prefix = "".join(g for g in "⇧⌃⌥⌘" if g in glyphs)
    return prefix + sym if prefix else sym


def _get_layer_from_conditions(conditions, base_layer):
    """Check conditions: if tab_modifier variable is required, add tab_mod to layer.
    Returns None if conditions make this rule context-specific (skip it)."""
    if not conditions: return base_layer
    for c in conditions:
        if c.get("type") == "variable_if" and c.get("name") == "tab_modifier":
            return base_layer | frozenset({"tab_mod"})
        if c.get("type") == "variable_if" and c.get("name") == "keyboard_disabled":
            return None  # keyboard lock — skip
    # Other conditions (frontmost_app, etc.) — skip these context-specific rules
    if any(c.get("type") in ("frontmost_application_if", "frontmost_application_unless")
           for c in conditions):
        return None
    return base_layer


def parse_karabiner():
    """Return {(frozenset_layer_mods, physical_key): display_string} from all rules."""
    conditional = {}   # rules with conditions (lower priority)
    unconditional = {} # rules without conditions
    for _, rule in layers.all_rules():
        for m in rule["manipulators"]:
            if m.get("type") != "basic": continue
            fr = m.get("from", {})
            fk = fr.get("key_code", "")
            if not fk: continue
            phys = _TO_PHYS.get(fk)
            if not phys: continue
            mandatory = fr.get("modifiers", {}).get("mandatory", [])
            base_layer = _from_mods_to_layer(mandatory)
            conditions = m.get("conditions", [])
            layer = _get_layer_from_conditions(conditions, base_layer)
            if layer is None: continue
            to_list = m.get("to", [])
            if not to_list: continue
            display = _to_display(to_list[0])
            if not display: continue
            key = (layer, phys)
            target = conditional if conditions else unconditional
            if key not in target:
                target[key] = display
    # Merge: unconditional wins, conditional fills gaps
    result = {**conditional, **unconditional}
    return result
