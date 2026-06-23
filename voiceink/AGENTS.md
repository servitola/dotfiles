# voiceink — backup of VoiceInk.app settings (local whisper.cpp dictation)

- `VoiceInk_Settings_Backup.json` is a manual export from VoiceInk.app's own Settings → backup feature: `generalSettings` (menu-bar-only, notch recorder, retention, toggle hotkey), the large `wordReplacements` dictionary (mostly RU mis-hearing → correct tech term fixups), and empty `customPrompts`/`customCloudModels`/`powerModeConfigs`.
- Not symlinked and not restored by the Makefile — there is no app-config path to link to. Restore manually inside VoiceInk.app by importing this JSON. It is a checked-in snapshot, not a live config.
- `version` field tracks the VoiceInk.app schema version (currently `1.74`); bump it only by re-exporting from a newer app build, not by hand.
- The runtime integration lives elsewhere: `../litellm/voiceink-shim/` wraps the `voiceink` CLI as an OpenAI `/v1/audio/transcriptions` endpoint on `127.0.0.1:8178`, wired into LiteLLM as the `voiceink-local` model. This directory only holds the GUI settings backup — it is independent of that shim.
- The `wordReplacements` here apply inside VoiceInk.app's own dictionary at transcription time, so the shim and the context-menu action (`../contextMenu/actions/Transcribe with VoiceInk.cmaction/`) both inherit these fixups for free.
