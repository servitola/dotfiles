# Style control — Gemini prefixes, speed, Azure SSML

How to shape delivery (tone, pace, emotion) per backend. The OpenAI-style
`instructions` request field is not part of this stack — each backend has its
own mechanism below.

## Gemini (`tts` / `tts-pro`): natural-language prefix in `input`

Gemini TTS is steerable by plain-language directions embedded in the text
itself. Prepend a short instruction before the content:

```json
{"model": "tts", "voice": "Kore",
 "input": "Say in a calm, measured voice, slightly slower than normal: Сегодня мы разберём три темы."}
```

Guidance (works the same in Russian — «Скажи бодро и с улыбкой: …»):

- Name the delivery concretely: "calm and steady", "brisk and energetic",
  "spooky whisper" — vague words like "nice" do nothing.
- One direction at a time; opposing instructions ("fast and slow") degrade output.
- Keep the prefix short — one sentence. Long stage directions eat the
  4096-char budget and can leak into the audio.
- Acronyms: spell the pronunciation in the text ("A-I" instead of "AI");
  same for tricky names — write a phonetic approximation.
- Pauses: punctuation and paragraph breaks already create natural pauses;
  use an ellipsis or em-dash for a deliberate beat.
- Iterate one change at a time; regenerate and listen rather than stacking
  five adjustments at once.

Caveat: a style prefix is extra conversational text, which raises the chance
of Gemini's "Model tried to generate text" 400 (surfaced as 500 — see
backends.md). If a styled request keeps failing, drop the prefix or switch
to Azure SSML.

Pace without a prefix: the OpenAI `speed` param (0.25–4.0) passes through
the proxy — `"speed": 1.15` for slightly faster, `0.85` for slower.

## Piper (`tts-piper`): none

Fixed voice, fixed delivery. The shim ignores `voice` and `speed`. If the
delivery matters, use Gemini or Azure instead.

## Azure (`tts-azure` / `tts-azure-ru`): SSML in `input`

Send raw SSML as `input` for precise rate/pitch/pause control:

```xml
<speak version="1.0" xml:lang="ru-RU">
  <voice name="ru-RU-DmitryNeural">
    <prosody rate="-15%" pitch="-2st">Добрый вечер.</prosody>
    <break time="500ms"/>
    Начнём.
  </voice>
</speak>
```

- `rate`: `x-slow`…`x-fast` or signed percent `-50%`..`+100%`.
- `pitch`: percent, semitones (`-12st`..`+12st`), or named values.
- `<break time="500ms"/>` for explicit pauses; Azure's own phrase-break
  model is good, so add breaks only where the default feels wrong.
- Escape `& < > " '` inside text nodes. A battle-tested escaping + wrapping
  implementation lives in `~/projects/dotfiles/litellm/greek-tts.sh`.
- With `tts-azure-ru` the proxy hook overwrites the `voice` request param,
  but the `<voice name="...">` inside SSML is what Azure actually honors.
