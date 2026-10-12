#!/usr/bin/env python3
"""Generate every karabiner/rules file that has a table in layers.toml (all but 00, 04, 26, 29, 32).

Inputs: karabiner/layers.toml (layer tables + [slots]), karabiner/layers.raw/*.json.

Usage:
  python3 gen_layers.py            # write the rule files, print which changed
  python3 gen_layers.py --check    # exit 1 with a diff when a file on disk differs, or a manipulator can never fire
"""
import argparse
import difflib
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import bridges
import layers
import shadow

DIFF_LINES = 20


def render():
    """stem → file text."""
    return {stem: layers.dumps(doc) for stem, doc in layers.build().items()}


def _on_disk(rules_dir, stem):
    path = os.path.join(rules_dir, f"{stem}.json")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def drift(rules_dir=bridges.RULES_DIR, texts=None):
    texts = render() if texts is None else texts
    return [stem for stem, text in texts.items() if _on_disk(rules_dir, stem) != text]


def orphans(rules_dir=bridges.RULES_DIR, texts=None):
    """Rule files nothing accounts for. Karabiner would still load them, so a table deleted
    from layers.toml has to take its file with it."""
    texts = render() if texts is None else texts
    on_disk = {os.path.splitext(name)[0] for name in os.listdir(rules_dir) if name.endswith(".json")}
    return sorted(on_disk - set(texts) - set(layers.HAND_WRITTEN))


def _karabiner_lint(paths):
    cli = shutil.which("karabiner_cli")
    if not cli:
        return
    proc = subprocess.run([cli, "--lint-complex-modifications", *paths], capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(f"karabiner_cli rejected the generated rules:\n{proc.stdout}{proc.stderr}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="report drift instead of writing")
    ap.add_argument("--rules-dir", default=bridges.RULES_DIR, help=argparse.SUPPRESS)
    ap.add_argument("--no-karabiner-lint", action="store_true", help="skip karabiner_cli after writing")
    args = ap.parse_args()

    try:
        texts = render()
    except ValueError as e:
        sys.exit(f"gen_layers: {e}")
    stale = drift(args.rules_dir, texts)
    stray = orphans(args.rules_dir, texts)
    if stray:
        sys.exit("gen_layers: neither generated nor hand-written, delete or add to layers.HAND_WRITTEN: "
                 + ", ".join(f"{stem}.json" for stem in stray))

    if args.check:
        for stem in stale:
            old = (_on_disk(args.rules_dir, stem) or "").splitlines()
            diff = list(difflib.unified_diff(old, texts[stem].splitlines(), f"{stem}.json (disk)",
                                             f"{stem}.json (generated)", lineterm="", n=1))
            print(f"{stem}.json differs from layers.toml + layers.raw")
            print("\n".join(diff[:DIFF_LINES]) + ("\n…" if len(diff) > DIFF_LINES else ""))
        shadowed = [] if stale else shadow.dead(args.rules_dir)
        for row in shadowed:
            print(shadow.describe(*row))
        sys.exit(1 if stale or shadowed else 0)

    for stem in stale:
        with open(os.path.join(args.rules_dir, f"{stem}.json"), "w", encoding="utf-8") as fh:
            fh.write(texts[stem])
        print(f"gen_layers: wrote {stem}.json")
    shadowed = shadow.dead(args.rules_dir)
    if shadowed:
        sys.exit("gen_layers: " + "\n".join(shadow.describe(*row) for row in shadowed))
    if not args.no_karabiner_lint:
        _karabiner_lint([os.path.join(args.rules_dir, f"{stem}.json") for stem in texts])


if __name__ == "__main__":
    main()
