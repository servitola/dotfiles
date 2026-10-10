#!/usr/bin/env python3
"""Checks for the deny-telegram-send PreToolUse hook.

    python3 test-deny-telegram-send.py

Uses a throwaway config, so it depends on nothing private and can run on any
clone. A guard that silently stops guarding is worse than no guard, hence the
"searching is not sending" and "own chat passes" cases alongside the denials.
"""
import json
import os
import subprocess

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "deny-telegram-send.py")
OWN = "-1001234567890"
STRICT = "/tmp/strict-topic"
LOOSE = "/tmp/ordinary-project"

# Split so this file does not trip the very guard it is testing.
S = "send" + "_message"
API = "send" + "Message"

CASES = [
    ("account send, anywhere",     f'python3 -c "from telethon import TelegramClient; c.{S}(p,1)"', LOOSE,  "deny"),
    ("account send in strict dir", f'python3 -c "app.{S}(p, 1)"',                                   STRICT, "deny"),
    ("searching is not sending",   f"grep -rn {S} .",                                               STRICT, "pass"),
    ("reading is not sending",     "cat client.py",                                                 STRICT, "pass"),
    ("bot api -> own chat",        f"curl -s http://localhost:8081/botX/{API} -d chat_id={OWN}",     LOOSE,  "pass"),
    ("bot api -> someone else",    f"curl -s http://localhost:8081/botX/{API} -d chat_id=555111",    LOOSE,  "ask"),
    ("bot api in strict dir",      f"curl -s http://localhost:8081/botX/{API} -d chat_id={OWN}",     STRICT, "deny"),
    ("send hidden behind &&",      f'ls && python3 -c "from telethon import c; c.{S}(1)"',          LOOSE,  "deny"),
    ("unrelated command",          "git status",                                                    STRICT, "pass"),
    ("commit message about it",    f'git commit -m "telethon {S} guard"',                           STRICT, "pass"),
    ("commit with substitution",   f'git commit -m "$(python3 -c \'telethon c.{S}(1)\')"',          STRICT, "deny"),
]


def run(command, cwd, own=OWN):
    env = dict(os.environ, TG_CHAT_MAIN=own, TG_STRICT_DIRS="strict-topic")
    payload = json.dumps({"tool_name": "Bash", "cwd": cwd,
                          "tool_input": {"command": command}})
    proc = subprocess.run(["python3", HOOK], input=payload, capture_output=True,
                          text=True, env=env)
    if proc.stderr.strip():
        print("   stderr:", proc.stderr.strip())
    if not proc.stdout.strip():
        return "pass"
    return json.loads(proc.stdout)["hookSpecificOutput"]["permissionDecision"]


fails = 0
for label, command, cwd, want in CASES:
    got = run(command, cwd)
    fails += got != want
    print(f"{'PASS' if got == want else 'FAIL'}  {label:<28} want={want:<5} got={got}")

# Without a chat id the guard must get stricter, never looser.
got = run(f"curl -s http://localhost:8081/botX/{API} -d chat_id={OWN}", LOOSE, own="")
fails += got != "ask"
print(f"{'PASS' if got == 'ask' else 'FAIL'}  {'no chat id -> still asks':<28} want=ask   got={got}")
print("\nall green" if not fails else f"\nfailures: {fails}")
raise SystemExit(1 if fails else 0)
