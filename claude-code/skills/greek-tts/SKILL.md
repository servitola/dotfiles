---
name: greek-tts
description: |
  Generate Greek-language audio (MP3) from text via the local LiteLLM proxy +
  Azure AI Speech. Single voice for monologues, two voices for dialogues —
  auto-detected from the text. Slightly slower than natural (rate -10%) by
  default for learning material.

  Use when: "озвучь по-гречески", "сгенерируй греческое аудио", "сделай аудио
  из текста", "проговори по-гречески", "греческий tts", "озвучь диалог",
  "запиши голос", "speak in greek", "greek audio", "generate greek tts",
  "speak this dialogue in greek".

  Do NOT use for: other languages (English/Russian/etc) — Azure neural voices
  exist for those but this skill is wired to the el-GR pair (Nestoras +
  Athina). For non-Greek TTS the user can call `~/projects/dotfiles/litellm/
  greek-tts.sh` directly with any Azure voice id and skip this skill.
---

# Greek TTS

Single helper does all the work:
`~/projects/dotfiles/litellm/greek-tts.sh OUT.mp3 < spec.json`

Build a JSON array of turns and pipe it in. The script returns the MP3 path on
stdout and a per-turn progress log on stderr.

## Stack

- **Proxy**: `http://localhost:4000` (LiteLLM, master key `sk-local-workbot`).
  If it's down, suggest `cd ~/projects/dotfiles/litellm && docker compose up -d`.
- **Model alias**: `tts-azure` → Azure AI Speech, resource `tts-greek` in
  West Europe, pricing tier F0 (500K chars/month free, recurring).
- **Endpoint used**: `/v1/audio/speech` (returns MP3 directly).
- **Greek voices (el-GR)**:
  - `el-GR-NestorasNeural` — male (the only Greek male neural voice Azure has)
  - `el-GR-AthinaNeural`   — female
  These are the **only two** Greek neural voices in Azure as of mid-2026.
  If the user asks for "third voice" or "another male" — tell them only these
  two exist and offer the Italian/English fallback or a different style on
  the same voice.

## Detect: monologue or dialogue?

Look at the input text. Treat it as a dialogue when **any** of these patterns
appear on multiple lines:

| Pattern               | Example                              |
|-----------------------|--------------------------------------|
| Latin A:/B:           | `A: Γεια σου` / `B: Καλώς το`        |
| Greek Α:/Β:           | `Α: Γεια σου` / `Β: Καλώς το`        |
| `<b>X:</b>` HTML      | `<b>Α:</b> Γεια σου`                 |
| Named speaker         | `Γιώργος: ...` / `Μαρία: ...`        |
| Em-dash turns         | `— Γεια σου.` / `— Καλώς το`         |

A single block of prose without speaker markers = monologue.

## Voice assignment

- **Monologue**: pick the voice that fits context. Default to
  `el-GR-NestorasNeural` (male) unless the speaker is clearly female (named
  Μαρία/Ελένη/etc., grammatical clues like feminine adjectives «ευχαριστημένη»,
  or the user says "женским голосом").
- **Dialogue (2 speakers)**: first speaker → `el-GR-NestorasNeural`,
  second speaker → `el-GR-AthinaNeural`. Override based on names if obviously
  gendered (e.g. «Γιώργο» is male, «Μαρία» is female).
- **Dialogue (3+ speakers)**: only two neural voices exist in Greek. Map the
  third+ speaker to one of the two voices with `rate` differing by 5%, OR
  use the same voice with a different SSML style if the speaker is supposed
  to sound distinct. Tell the user this is a limitation.

## Build the JSON spec

Minimum shape — array, each turn has `voice` and `text`. Strip out the
speaker prefix (`A:`, `Α:`, `<b>...</b>`) from the text before sending —
the TTS shouldn't read "Альфа двоеточие" out loud.

```json
[
  {"voice": "el-GR-NestorasNeural", "text": "Άκου, Γιώργο, βρήκα δουλειά."},
  {"voice": "el-GR-AthinaNeural",   "text": "Σοβαρά; Πού;"}
]
```

Optional per-turn fields:
- `rate` — overrides the default `-10%`. Use `-20%` if the user says
  «ещё медленнее», `-30%` for «совсем медленно», `+0%` or `0%` for natural,
  `+10%` for «быстрее». Accepts Azure SSML rate syntax.
- `ssml` (bool) — `true` means `text` is raw SSML, passed unchanged. Use
  when you need styled speech that rate can't express (e.g. «excited»,
  «sad»). Greek voices support **only the `general` style** as of mid-2026,
  so styled output is moot for Greek — don't reach for `ssml: true` unless
  you have a clear reason.

## Invocation

```bash
jq -n '[
  {"voice":"el-GR-NestorasNeural","text":"..."},
  {"voice":"el-GR-AthinaNeural","text":"..."}
]' | ~/projects/dotfiles/litellm/greek-tts.sh /tmp/greek_<short-id>.mp3
```

Pick a meaningful filename: `/tmp/greek_motorbike_dialogue.mp3` is better
than `out.mp3` — the user may want to keep it. If you're working inside a
project directory (e.g. `~/projects/serho_topics/...`), save into that dir
instead of `/tmp`.

For Russian texts containing parenthetical translations interleaved with
Greek (the common «эталонный диалог» format), strip every translation line
before building turns — the user wants Greek audio only.

## Send the result

The skill is usually invoked from Telegram. After the MP3 is generated,
ship it back via the `mcp__bot__send_document` MCP tool with a short
caption naming the voice(s) and rate. Telegram renders MP3s with an inline
player, so the user just taps to listen — no manual download needed.

If the user is in a regular CLI session (no bot tools), just `open` the
file so Quick Look / iTunes plays it.

## Caching

Per-turn MP3s are cached at `~/.cache/greek-tts/<sha256>.mp3` keyed by
voice + rate + final SSML. Re-running with the same text is free. To
force-regenerate (e.g. testing a voice change), nuke the cache:

```bash
rm -rf ~/.cache/greek-tts
```

## Failure modes

- **HTTP 401/403 from proxy** → master key drifted; check
  `LITELLM_MASTER_KEY` env var matches `sk-local-workbot` in
  `~/projects/dotfiles/litellm/docker-compose.yml`.
- **HTTP 401 from Azure (visible in proxy logs)** → `AZURE_VOICE_TTS_GREEK_API_KEY1`
  expired or was regenerated; fetch a fresh one from Azure portal
  → `tts-greek` resource → `Keys and Endpoint` → KEY 1.
- **HTTP 429 from Azure** → F0 free tier exhausted for the month (500K
  chars). Either wait for monthly reset or temporarily switch the resource
  to S0 pricing in the portal (now charges $4/1M chars).
- **Empty reply from proxy** → container is starting; `docker compose logs
  -f litellm` until it says `Application startup complete`.

## SSML cheat sheet (when you need it)

```xml
<speak version="1.0" xml:lang="el-GR">
  <voice name="el-GR-NestorasNeural">
    <prosody rate="-15%" pitch="-2st">Καλημέρα, φίλε μου.</prosody>
    <break time="500ms"/>
    Πώς πάει;
  </voice>
</speak>
```

- `rate`: `x-slow`/`slow`/`medium`/`fast`/`x-fast` or signed percent `-50%`..`+100%`.
- `pitch`: `-50%`..`+50%`, semitones `-12st`..`+12st`, or named.
- `<break time="500ms"/>`: explicit pause. Don't sprinkle breaks for natural
  prose — Azure's phrase-break model is already good.

Pass via the `ssml` field on the turn object.
