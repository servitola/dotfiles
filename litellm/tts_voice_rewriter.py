"""Per-deployment voice override for /v1/audio/speech.

Bot clients (e.g. serho) call `model="tts"` with a Gemini voice name
("Kore", "Puck", …). When the router fails over from Gemini to an Azure
deployment (`tts-azure-ru`), the Gemini voice id is meaningless to Azure
and would 400 with "Voice does not exist". This hook detects fallback-
resolved Azure deployments by model name and substitutes a sane Azure
neural voice before the request reaches the upstream.

The hook is intentionally narrow: it only rewrites when the resolved
deployment name appears in MODEL_VOICE_OVERRIDES. The voice-agnostic
`tts-azure` deployment (used by the greek-tts skill, which sends explicit
Azure voice ids per turn) is NOT touched.

Wired in config.yaml alongside redact_secrets:
    litellm_settings:
      callbacks:
        - redact_secrets.redact_secrets_instance
        - tts_voice_rewriter.tts_voice_rewriter_instance
"""
from __future__ import annotations

from typing import Optional

from litellm.integrations.custom_logger import CustomLogger

MODEL_VOICE_OVERRIDES: dict[str, str] = {
    "tts-azure-ru": "ru-RU-DmitryNeural",
}


class TTSVoiceRewriter(CustomLogger):
    async def async_pre_call_hook(
        self,
        user_api_key_dict,
        cache,
        data: dict,
        call_type: str,
    ) -> Optional[dict]:
        if call_type not in ("aspeech", "speech"):
            return data
        model = data.get("model", "")
        override = MODEL_VOICE_OVERRIDES.get(model)
        if override:
            data["voice"] = override
        return data


tts_voice_rewriter_instance = TTSVoiceRewriter()
