#!/usr/bin/env python3
"""Every require and Spoon that the committed Hammerspoon config loads must be in the
index or installed by install/18-spoons.sh. The working tree is no proof: an untracked
module loads fine here and is missing on every other machine."""
import re
import subprocess
import sys

tracked = set(subprocess.run(["git", "ls-files", "hammerspoon", "install/18-spoons.sh"],
                             capture_output=True, text=True, check=True).stdout.split())

def staged(path):
    return subprocess.run(["git", "show", f":{path}"], capture_output=True, text=True, check=True).stdout

installed = set(re.findall(r"^install_spoon (\w+)", staged("install/18-spoons.sh"), re.M))
REQUIRE = re.compile(r"""(?<![\w.])require\s*\(?\s*["']([\w.]+)["']""")
SPOON = re.compile(r"""(?:safeLoadSpoon|hs\.loadSpoon)\(\s*["'](\w+)["']""")

missing = []
for path in sorted(p for p in tracked if p.endswith(".lua")):
    code = "\n".join(line.split("--")[0] for line in staged(path).splitlines())
    spoon = re.match(r"hammerspoon/Spoons/[^/]+\.spoon", path)
    for module in REQUIRE.findall(code):
        if module.split(".")[0] == "hs":
            continue
        rel = module.replace(".", "/")
        candidates = [f"hammerspoon/{rel}.lua", f"hammerspoon/{rel}/init.lua"]
        if spoon:
            candidates.append(f"{spoon.group(0)}/{rel}.lua")
        if not tracked.intersection(candidates):
            missing.append(f"{path}: require \"{module}\" is not committed")
    for name in SPOON.findall(code):
        if name not in installed and f"hammerspoon/Spoons/{name}.spoon/init.lua" not in tracked:
            missing.append(f"{path}: Spoon {name} is neither committed nor in install/18-spoons.sh")

print("\n".join(missing), file=sys.stderr)
sys.exit(1 if missing else 0)
