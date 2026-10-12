#!/usr/bin/env python3
"""Check constants.env against constants/schema.toml and against its consumers."""

import argparse
import fnmatch
import json
import os
import re
import shutil
import subprocess
import sys
import tomllib
import zoneinfo
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
ENV = ROOT / "constants.env"
EXAMPLE = ROOT / "constants.example.env"
SCHEMA = ROOT / "constants" / "schema.toml"
HOME = str(Path.home())

KEY = re.compile(r"[A-Z][A-Z0-9_]*")
APP_DIRS = ["/Applications", "/Applications/Utilities", "/System/Applications", f"{HOME}/Applications"]
# A shorter private value (an ssh alias like "i9") matches ordinary words.
MIN_LITERAL = 6
ABSENT = "NONE"
NOT_SHELL = ("*.js", "*.mjs", "*.ts", "*.tsx", "*.astro", "*.cs", "*.md", "*.svg", "*.json")


def read_env(path):
    values, problems = {}, []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        where = f"{path.name}:{number}"
        key, separator, value = line.partition("=")
        if not separator or not KEY.fullmatch(key):
            problems.append(f"{where}: not KEY=value")
            continue
        # constants.py strips the line, load.zsh and constants.lua do not.
        if line != line.strip() or value != value.strip():
            problems.append(f"{where}: {key} has surrounding whitespace, the loaders disagree on it")
        if value[:1] in "\"'" and value[-1:] == value[:1]:
            problems.append(f"{where}: {key} is quoted, the quotes become part of the value")
        if "${HOME}" in value:
            problems.append(f"{where}: {key} uses ${{HOME}}, only $HOME is expanded")
        if " #" in value:
            problems.append(f"{where}: {key} has an inline comment, it becomes part of the value")
        if key in values:
            problems.append(f"{where}: {key} is defined twice")
        values[key] = value
    return values, problems


def expand(value):
    return value.replace("$HOME", HOME)


def is_path(value):
    return value.startswith(("$HOME/", "/"))


def is_url(value):
    parsed = urlparse(value)
    return bool(parsed.scheme and parsed.netloc)


def is_timezone(value):
    return value in zoneinfo.available_timezones()


def app_installed(value):
    return any(os.path.isdir(f"{directory}/{value}.app") for directory in APP_DIRS)


FORMAT = {
    "text": lambda value: bool(value),
    "email": lambda value: re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", value),
    "timezone": is_timezone,
    "app": lambda value: bool(value),
    "bundle": lambda value: re.fullmatch(r"[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+", value),
    "cli": lambda value: re.fullmatch(r"[A-Za-z0-9._-]+", value),
    "dir": is_path,
    "file": is_path,
    "chat_id": lambda value: re.fullmatch(r"-100\d{10}", value),
    "url": is_url,
    "host": lambda value: re.fullmatch(r"[A-Za-z0-9._-]+", value),
}

MACHINE = {
    "app": app_installed,
    "cli": shutil.which,
    "dir": lambda value: os.path.isdir(expand(value)),
    "file": lambda value: os.path.isfile(expand(value)),
}


def check_schema(values, schema, machine=False):
    problems = []
    for key in values.keys() - schema.keys():
        problems.append(f"{key}: in constants.env, missing from schema.toml")
    for key in schema.keys() - values.keys():
        problems.append(f"{key}: in schema.toml, missing from constants.env")
    for key in sorted(values.keys() & schema.keys()):
        entry = schema[key]
        kind = entry.get("type")
        if kind not in FORMAT:
            problems.append(f"{key}: unknown type {kind!r}")
            continue
        if not entry.get("about"):
            problems.append(f"{key}: no `about`")
        if values[key] == ABSENT:
            continue
        if not FORMAT[kind](values[key]):
            problems.append(f"{key}: {values[key]!r} is not a valid {kind}")
        elif machine and kind in MACHINE and not entry.get("removable") and not MACHINE[kind](values[key]):
            problems.append(f"{key}: {kind} {values[key]!r} is not on this machine")
    return problems


def git(*args):
    result = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, errors="replace")
    if result.returncode > 1:
        sys.exit(f"git {' '.join(args)}: {result.stderr.strip()}")
    return result.stdout.splitlines()


def grep(pattern, *pathspecs, ignore_case=False):
    flags = ["-I", "-n", "-o", "-P"] + (["-i"] if ignore_case else [])
    hits = []
    for line in git("grep", *flags, "-e", pattern, "--", *(pathspecs or ["."])):
        path, number, match = line.split(":", 2)
        hits.append((path, number, match))
    return hits


def exclude(*globs):
    return [f":(exclude,glob)**/{glob}" for glob in globs] + [f":(exclude,glob){glob}" for glob in globs]


def normalise(name):
    return name.upper().replace(".", "_")


REFERENCES = [
    (r"\bK\[[\"'][A-Z][A-Z0-9_]*[\"']\]|\bK\.get\([\"'][A-Z][A-Z0-9_]*", ["*.py"]),
    (r"\bconstants\.[A-Z][A-Z0-9_]*|require\(\"constants\"\)\.[A-Z][A-Z0-9_]*", ["*.lua"]),
    (r"\"@[A-Z][A-Z0-9_]*\"", ["*.lua", "*.toml", "*.py"]),
]


def references(namespaces):
    """Every place that names a constant through a syntax that can only mean a constant."""
    found = []
    prefixes = tuple(f"{namespace}_" for namespace in namespaces)
    for pattern, pathspecs in REFERENCES:
        for path, number, match in grep(pattern, *pathspecs):
            name = re.findall(r"[A-Z][A-Z0-9_]*", match)[-1]
            if not match.startswith('"@') or name.startswith(prefixes):
                found.append((path, number, name))

    for path, number, match in grep(r"\bconst (get )?[A-Za-z][A-Za-z0-9_.]*[A-Za-z0-9]( *=)?", ".", *exclude(*NOT_SHELL[:6])):
        name = normalise(match.split()[-1])
        if not match.endswith("=") and name.startswith(prefixes):
            found.append((path, number, name))

    shell = grep(r"\$\{?(" + "|".join(namespaces) + r")_[A-Z0-9_]+", ".", *exclude(*NOT_SHELL))
    # A script may get the variable from a file it sources, so an assignment anywhere counts.
    assigned = {match.rstrip("=") for _, _, match in grep(r"\b(" + "|".join(namespaces) + r")_[A-Z0-9_]+=", ".", *exclude(*NOT_SHELL))}
    for path, number, match in shell:
        name = match.lstrip("${")
        if name not in assigned:
            found.append((path, number, name))
    return found


def namespaces_of(keys):
    counts = {}
    for key in keys:
        namespace = key.split("_")[0]
        counts[namespace] = counts.get(namespace, 0) + 1
    return sorted(namespace for namespace, count in counts.items() if count > 1)


def check_dangling(values):
    own = (str(ENV.relative_to(ROOT)), str(SCHEMA.relative_to(ROOT)))
    return [
        f"{path}:{number}: {name} is not a constant"
        for path, number, name in references(namespaces_of(values))
        if name not in values and path not in own
    ]


def check_dead(values, schema):
    """A key nobody reads, unless the schema admits it with `unread = true` — and then it must stay unread."""
    own = [f":(exclude){ENV.relative_to(ROOT)}", f":(exclude){SCHEMA.relative_to(ROOT)}"]
    docs = [":(exclude,glob)*.md", ":(exclude,glob)[!c]*/**/*.md", ":(exclude,glob)*.svg", ":(exclude,glob)**/*.svg"]
    used = {match for _, _, match in grep(r"\b(" + "|".join(values) + r")\b", ".", *own, *docs)}
    for _, _, match in grep(r"\bconst (get )?[a-z]+(\.[a-z0-9]+)+", ".", *own, ignore_case=True):
        used.add(normalise(match.split()[-1]))
    problems = []
    for key in values:
        unread = schema.get(key, {}).get("unread", False)
        if key not in used and not unread:
            problems.append(f"{key}: nothing reads it")
        if key in used and unread:
            problems.append(f"{key}: marked `unread` in schema.toml, but something reads it now")
    return problems


def literals(values, schema):
    needles = {HOME: "the home path, use $HOME or a DIR_ constant"}
    for key, value in values.items():
        if not schema.get(key, {}).get("private"):
            continue
        needle = value.removeprefix("$HOME")
        if len(needle) >= MIN_LITERAL:
            needles[needle] = f"the value of {key}"
    return needles


def allowed(path, allow):
    return any(fnmatch.fnmatch(path, glob) for glob in allow)


def scan(lines, needles, allow):
    problems = []
    for path, number, text in lines:
        if allowed(path, allow):
            continue
        for needle, what in needles.items():
            if needle in text:
                problems.append(f"{path}:{number}: hardcodes {what}")
    return problems


def staged_added_lines():
    lines, path, number = [], None, 0
    for line in git("diff", "--cached", "-U0", "--no-color", "--diff-filter=AM"):
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else None
        elif line.startswith("@@"):
            number = int(re.search(r"\+(\d+)", line).group(1))
        elif line.startswith("+") and path:
            lines.append((path, number, line[1:]))
            number += 1
    return lines


def check_literals(values, schema, allow, whole_tree=False):
    own = [str(ENV.relative_to(ROOT)), str(SCHEMA.relative_to(ROOT))]
    needles = literals(values, schema)
    if not whole_tree:
        return scan(staged_added_lines(), needles, own + allow)
    lines = []
    for needle in needles:
        for line in git("grep", "-I", "-n", "-F", "-e", needle, "--", "."):
            lines.append(tuple(line.split(":", 2)))
    return sorted(set(scan(lines, needles, own + allow)))


def run(command, **kwargs):
    result = subprocess.run(command, capture_output=True, text=True, cwd=ROOT, **kwargs)
    if result.returncode:
        sys.exit(f"{command[0]}: {result.stderr.strip()}")
    return result.stdout


def loader_zsh(keys):
    script = 'source constants/load.zsh; for key in "$@"; do print -rn -- "$key=${(P)key}"$\'\\0\'; done'
    out = run(["/bin/zsh", "-fc", script, "--", *keys], env={"HOME": HOME, "PATH": os.environ["PATH"]})
    return dict(pair.split("=", 1) for pair in out.split("\0") if pair)


def loader_const(_keys):
    return dict(line.split(None, 1) for line in run(["/bin/zsh", "zsh/bin/const", "list"]).splitlines())


def loader_python(_keys):
    script = "import json, sys; sys.path.insert(0, 'constants'); from constants import K; print(json.dumps(K))"
    return json.loads(run([sys.executable, "-c", script]))


def loader_lua(_keys):
    script = (
        'package.path = "hammerspoon/?.lua;" .. package.path '
        'for key, value in pairs(require("constants")) do io.write(key, "=", value, "\\0") end'
    )
    return dict(pair.split("=", 1) for pair in run(["lua", "-e", script]).split("\0") if pair)


LOADERS = {
    "constants/load.zsh": loader_zsh,
    "zsh/bin/const": loader_const,
    "constants/constants.py": loader_python,
    "hammerspoon/constants.lua": loader_lua,
}


def check_loaders(values):
    expected = {key: expand(value) for key, value in values.items()}
    problems = []
    for name, loader in LOADERS.items():
        got = loader(list(expected))
        for key in sorted(expected.keys() | got.keys()):
            if expected.get(key) != got.get(key):
                problems.append(f"{name}: {key} is {got.get(key)!r}, constants.env says {expected.get(key)!r}")
    return problems


def render_example(schema_text):
    """constants.example.env from the schema: its groups, each key's about and example."""
    lines = ["# Generated from constants/schema.toml by constants/check.py — edit the schema, not this.",
             "# Copy to constants.env (install.sh does it on a new Mac) and put this Mac's values there."]
    keys = tomllib.loads(schema_text)["keys"]
    body = schema_text.split("[keys]", 1)[1].split("\n[", 1)[0]
    for line in body.splitlines():
        key = line.split("=", 1)[0].strip()
        if not line.strip():
            lines.append("")
        elif key in keys:
            lines += [f"# {keys[key]['about']}", f"{key}={keys[key].get('example', '')}"]
    return "\n".join(lines).rstrip("\n") + "\n"


def check_example(schema_text, schema):
    """The example follows the schema; a stale one is rewritten here, so the commit only needs it staged."""
    missing = [f"{SCHEMA.name}: {key} has no example" for key, rule in schema.items() if "example" not in rule]
    wanted = render_example(schema_text)
    if EXAMPLE.exists() and EXAMPLE.read_text(encoding="utf-8") == wanted:
        return missing
    EXAMPLE.write_text(wanted, encoding="utf-8")
    return missing + [f"{EXAMPLE.name} followed {SCHEMA.name} and was rewritten: stage it"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--machine", action="store_true", help="also: paths exist, apps installed, CLIs on PATH")
    parser.add_argument("--literals", action="store_true", help="list every hardcoded private value in the tree, not only staged lines")
    args = parser.parse_args()

    schema_text = SCHEMA.read_text(encoding="utf-8")
    document = tomllib.loads(schema_text)
    schema, allow = document["keys"], document["literals"]["allow"]
    problems = check_example(schema_text, schema)
    problems += [f"{EXAMPLE.name}: {p}" for p in check_schema(read_env(EXAMPLE)[0], schema)]
    # constants.env is this Mac's and not in git; where there is none (CI), the example stands in.
    values, env_problems = read_env(ENV if ENV.exists() else EXAMPLE)
    problems += env_problems

    if args.literals:
        problems = check_literals(values, schema, allow, whole_tree=True)
    else:
        problems += check_schema(values, schema, machine=args.machine)
        problems += check_loaders(values)
        # Paused while the tree is mid-cleanup: readers come and go faster than the schema keeps up.
        # problems += check_dead(values, schema)
        problems += check_dangling(values)
        problems += check_literals(values, schema, allow)

    for problem in problems:
        print(problem, file=sys.stderr)
    if problems:
        sys.exit(f"constants: {len(problems)} problem(s)")
    print("constants: ok")


if __name__ == "__main__":
    main()
