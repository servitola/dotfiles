#!/usr/bin/env python3
"""PreToolUse(Bash) — the agent never sends Telegram messages to other people.

Two locks, deliberately different in strength:

  deny  sending / forwarding / editing anything through a Telegram **user
        account** session (Telethon, Pyrogram, telegram-cli). That session is
        the owner's own account: a message sent through it reaches a real
        person under the owner's name. No confirmation is offered — this is a
        standing rule, not a judgement call.

  ask   raw Bot API sends (`sendMessage`, `sendPhoto`, …) aimed at a chat that
        is not one of the owner's own. Scheduled jobs delivering into the
        owner's own chat pass silently; anything pointed at another human
        stops for a confirmation.

Read-only commands pass untouched: `grep -rn send_message`, `cat client.py`
and friends are searches, not sends, so the first token of each shell segment
is checked against a read-only allowlist before the patterns run.

The own chat id and the directories that are strict (no sends at all, not even
the ask path) are machine constants: TG_CHAT_MAIN and TG_STRICT_DIRS, read from
the environment or constants.env. Without a chat id the guard still works and
simply asks about every Bot API send.

Fails open — a broken guard must never wedge the session.
"""

import json
import os
import re
import shlex
import sys


SEPARATORS = set("();<>|&`") | {"||", "&&", ";;", ">>", "<<"}

# Prefixes standing in front of the real command.
WRAPPERS = {"sudo", "doas", "command", "builtin", "exec", "nohup", "time",
            "nice", "env", "stdbuf", "xargs", "caffeinate", "rtk", "proxy"}

# Commands that only look at bytes. Searching for "send_message" is not sending.
READ_ONLY = {"grep", "rg", "ag", "cat", "bat", "head", "tail", "less", "more",
             "ls", "find", "fd", "wc", "diff", "jq", "echo", "printf", "awk",
             "cut", "sort", "uniq", "file", "stat", "tree", "open"}

# Tools that carry prose in their arguments and cannot reach Telegram whatever
# is written there — a commit message describing this very guard must not trip
# it. Skipped only when the segment has no command substitution, so
# `git commit -m "$(...)"` is still inspected.
PROSE_CARRIERS = {"git", "gh", "glab", "hg", "svn", "jj"}
SUBSTITUTION = re.compile(r"\$\(|<\(|\$\{")

ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z_0-9]*=")

# Acting on messages from a logged-in *account*.
USERBOT_ACTIONS = re.compile(
    r"\b(send_message|send_file|send_media|send_photo|send_video|send_voice|"
    r"send_document|send_audio|forward_messages|forward_to|send_reaction|"
    r"send_read_acknowledge|edit_message|delete_messages|"
    r"messages\.SendMessage|SendMessageRequest|ForwardMessagesRequest)\b",
    re.I,
)

# …through a personal-account client rather than a bot.
USERBOT_CONTEXT = re.compile(
    r"(telethon|TelegramClient|pyrogram|telegram-cli|tdlib|\.session\b)",
    re.I,
)

# Bot API write endpoints, however they are spelled in a URL.
BOT_API_SEND = re.compile(
    r"/(sendMessage|sendPhoto|sendDocument|sendVideo|sendAnimation|sendVoice|"
    r"sendAudio|sendSticker|copyMessage|forwardMessage)\b",
    re.I,
)

CHAT_ID = re.compile(r"chat_id[\"'\s:=]+(-?\d+)")

DENY_REASON = (
    "Отправка сообщений от личного аккаунта запрещена навсегда. "
    "Покажи текст в чате — отправит его человек сам."
)


def config():
    """TG_CHAT_MAIN and TG_STRICT_DIRS from the machine constants; a missing or
    empty chat id only makes the guard stricter (every send asks)."""
    own = setting("TG_CHAT_MAIN")
    strict = setting("TG_STRICT_DIRS")
    return ([own] if own else [], [d for d in strict.split(",") if d])


def setting(name):
    """The environment wins (every zsh exports the constants, and tests override
    them there); constants.env is the fallback for a process that inherited no shell."""
    if name in os.environ:
        return os.environ[name]
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "..", "constants"))
    try:
        from constants import K
    except Exception:
        return ""
    return K.get(name, "")


def lex(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars="();<>|&`")
    lexer.whitespace_split = True
    return list(lexer)


def segments(tokens):
    current = []
    for token in tokens:
        if token in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(token)
    if current:
        yield current


def head_binary(segment):
    """First token that is not an env-assignment or a wrapper."""
    for token in segment:
        if ASSIGNMENT.match(token) or os.path.basename(token) in WRAPPERS:
            continue
        return os.path.basename(token)
    return None


def acting_segments(command):
    """Shell segments that could actually do something, as plain strings.

    An unparseable command is not a reason to stop guarding, so a lexing
    failure falls back to treating the whole command as one acting segment.
    """
    try:
        parsed = list(segments(lex(command)))
    except ValueError:
        return [command]

    acting = []
    for segment in parsed:
        binary = head_binary(segment)
        if binary in READ_ONLY:
            continue
        chunk = " ".join(segment)
        if binary in PROSE_CARRIERS and not SUBSTITUTION.search(chunk):
            continue
        acting.append(chunk)
    return acting


def verdict(command, cwd, own_chat_ids, strict_dirs):
    """(decision, reason) or None when the command is fine."""
    strict = any(marker in (cwd or "") for marker in strict_dirs)

    for chunk in acting_segments(command):
        if USERBOT_ACTIONS.search(chunk) and (USERBOT_CONTEXT.search(chunk) or strict):
            return "deny", DENY_REASON

        if BOT_API_SEND.search(chunk):
            if strict:
                return "deny", (
                    "В этом каталоге любая отправка сообщений запрещена. "
                    "Отдай черновик текстом."
                )
            outside = [t for t in CHAT_ID.findall(chunk) if t not in own_chat_ids]
            if outside or not own_chat_ids:
                target = ", ".join(outside) if outside else "неизвестный чат"
                return "ask", (
                    f"Команда шлёт сообщение в чужой чат ({target}), "
                    f"а не в твой собственный. Подтверди."
                )
    return None


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") != "Bash":
        return
    own_chat_ids, strict_dirs = config()
    result = verdict(
        payload.get("tool_input", {}).get("command", ""),
        payload.get("cwd", ""),
        own_chat_ids,
        strict_dirs,
    )
    if not result:
        return
    decision, reason = result
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # fail-open: a broken guard must not wedge the session
        print(f"deny-telegram-send hook error: {exc}", file=sys.stderr)
    sys.exit(0)
