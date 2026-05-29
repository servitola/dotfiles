"""Pre-call secret redaction for LiteLLM.

Strips common secret patterns from outgoing messages before they hit any
upstream provider — protects against leaking API keys, AWS keys, GitHub
PATs, JWTs, or private keys to OpenRouter / Mistral free tier / etc.
The same redaction propagates into spend_logs since LiteLLM logs the
post-hook payload.

Wired in config.yaml as:
    litellm_settings:
      callbacks: redact_secrets.redact_secrets_instance
"""
from __future__ import annotations

import re
from typing import Any, Literal, Optional

from litellm.integrations.custom_logger import CustomLogger

_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"sk-ant-[a-zA-Z0-9_\-]{20,}"), "sk-ant-[REDACTED]"),
    (re.compile(r"sk-proj-[a-zA-Z0-9_\-]{20,}"), "sk-proj-[REDACTED]"),
    (re.compile(r"sk-[a-zA-Z0-9_\-]{20,}"), "sk-[REDACTED]"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AKIA[REDACTED]"),
    (re.compile(r"ASIA[0-9A-Z]{16}"), "ASIA[REDACTED]"),
    (re.compile(r"ghp_[a-zA-Z0-9]{36}"), "ghp_[REDACTED]"),
    (re.compile(r"gho_[a-zA-Z0-9]{36}"), "gho_[REDACTED]"),
    (re.compile(r"ghs_[a-zA-Z0-9]{36}"), "ghs_[REDACTED]"),
    (re.compile(r"github_pat_[a-zA-Z0-9_]{40,}"), "github_pat_[REDACTED]"),
    (re.compile(r"glpat-[a-zA-Z0-9_\-]{20,}"), "glpat-[REDACTED]"),
    (re.compile(r"xox[baprs]-[a-zA-Z0-9\-]{10,}"), "xox-[REDACTED]"),
    (re.compile(r"eyJ[a-zA-Z0-9_\-]+\.eyJ[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+"), "[JWT_REDACTED]"),
    (re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----[\s\S]+?-----END[^-]+-----"), "[PRIVATE_KEY_REDACTED]"),
    (re.compile(r"AIza[0-9A-Za-z_\-]{35}"), "AIza[REDACTED]"),
]


def _redact(text: str) -> str:
    for pattern, replacement in _PATTERNS:
        text = pattern.sub(replacement, text)
    return text


def _redact_any(value: Any) -> Any:
    if isinstance(value, str):
        return _redact(value)
    if isinstance(value, list):
        return [_redact_any(v) for v in value]
    if isinstance(value, dict):
        if isinstance(value.get("text"), str):
            value = {**value, "text": _redact(value["text"])}
        return value
    return value


def _redact_messages(messages: Any) -> None:
    if not isinstance(messages, list):
        return
    for msg in messages:
        if not isinstance(msg, dict):
            continue
        content = msg.get("content")
        if isinstance(content, str):
            msg["content"] = _redact(content)
        elif isinstance(content, list):
            msg["content"] = [_redact_any(p) for p in content]


class RedactSecrets(CustomLogger):
    async def async_pre_call_hook(
        self,
        user_api_key_dict,
        cache,
        data: dict,
        call_type: Literal[
            "completion",
            "text_completion",
            "embeddings",
            "image_generation",
            "moderation",
            "audio_transcription",
            "responses",
        ],
    ) -> Optional[dict]:
        _redact_messages(data.get("messages"))
        if "prompt" in data:
            data["prompt"] = _redact_any(data["prompt"])
        if "input" in data:
            data["input"] = _redact_any(data["input"])
        return data


redact_secrets_instance = RedactSecrets()
