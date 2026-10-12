#!/usr/bin/env python3
"""Build karabiner.json from layers.toml, hand/ and karabiner-template.json.

Usage:
  python3 gen_rules.py            # write karabiner.json (build.sh runs this)
  python3 gen_rules.py --check    # generate in memory only: exit 1 on a row the grammar
                                  # rejects or a manipulator that can never fire
  python3 gen_rules.py --dump DIR # also write every rule as DIR/<stem>.json, to read or diff
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import layers
import shadow


def dumps(doc):
    return json.dumps(doc, indent=4, ensure_ascii=False) + "\n"


def dump(rules, directory):
    os.makedirs(directory, exist_ok=True)
    paths = []
    for stem, rule in rules:
        paths.append(os.path.join(directory, f"{stem}.json"))
        with open(paths[-1], "w", encoding="utf-8") as fh:
            fh.write(dumps(rule))
    return paths


def _karabiner_lint(rules):
    cli = shutil.which("karabiner_cli")
    if not cli:
        return
    with tempfile.TemporaryDirectory() as tmp:
        proc = subprocess.run([cli, "--lint-complex-modifications", *dump(rules, tmp)], capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(f"karabiner_cli rejected the rules:\n{proc.stdout}{proc.stderr}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="generate in memory, write nothing")
    ap.add_argument("--dump", metavar="DIR", help="also write each rule to DIR/<stem>.json")
    ap.add_argument("--output", default=layers.OUTPUT_PATH, help=argparse.SUPPRESS)
    args = ap.parse_args()

    try:
        rules = layers.all_rules()
    except ValueError as e:
        sys.exit(f"gen_rules: {e}")
    shadowed = shadow.dead(rules)
    if shadowed:
        sys.exit("gen_rules: " + "\n".join(shadow.describe(*row) for row in shadowed))
    if args.dump:
        dump(rules, args.dump)
    if args.check:
        return
    _karabiner_lint(rules)
    tmp = args.output + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(dumps(layers.config(rules)))
    os.replace(tmp, args.output)
    print(f"Built karabiner.json: {len(rules)} rules, {sum(len(r['manipulators']) for _, r in rules)} manipulators")


if __name__ == "__main__":
    main()
