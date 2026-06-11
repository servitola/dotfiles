---
name: humanizer
description: |
  Humanize text: strip AI-isms and add real human voice.

  Use when: "очеловечь текст", "убери AI-стиль", "humanize this", "de-slop this draft"
---

# Humanizer: Remove AI Writing Patterns

Identify and remove signs of AI-generated text to make writing sound natural and human. Based on Wikipedia's "Signs of AI writing" guide (maintained by WikiProject AI Cleanup), derived from observations of thousands of AI-generated text instances.

**Key insight:** LLMs use statistical algorithms to guess what should come next. The result tends toward the most statistically likely completion, which is how the telltale patterns below get baked in.

## When to use this skill

Load this skill whenever the user asks to:
- "humanize", "de-AI", "de-slop", or "un-ChatGPT" a piece of text
- rewrite something so it doesn't sound like it was written by an LLM
- edit a draft (blog post, essay, PR description, docs, memo, email, tweet, resume bullet) to sound more natural
- match their voice in writing they're producing
- review text for AI tells before publishing

Also apply this skill to **your own** output when writing user-facing prose — release notes, PR descriptions, documentation, long-form explanations, summaries. Your baseline voice already strips most of these, but a focused pass catches what slips through.

## How to use it

The text usually arrives one of three ways:
1. **Inline** — user pastes the text directly into the message. Work on it in-place, reply with the rewrite.
2. **File** — user points at a file. Use `Read` to load it, then `Edit` or `Write` to apply edits. For markdown docs in a repo, a targeted `Edit` per section is cleaner than rewriting the whole file.
3. **Voice calibration sample** — user provides an additional sample of their own writing (inline or by file path) and asks you to match it. Read the sample first, analyze it following [voice-and-soul.md](references/voice-and-soul.md) (sentence length, word choice, punctuation habits, transitions), then rewrite.

Always show the rewrite to the user. For file edits, show a diff or the changed section — don't silently overwrite.

## Your task

When given text to humanize:

1. **Identify AI patterns** — scan against the full catalog in [patterns.md](references/patterns.md) (words to watch, before/after rewrites for all 29 patterns). The checklist below is the index; the catalog has the detail.
2. **Rewrite problematic sections** — replace AI-isms with natural alternatives.
3. **Preserve meaning** — keep the core message intact.
4. **Maintain voice** — match the intended tone (formal, casual, technical, etc.). If a voice sample was provided, match it specifically.
5. **Add soul** — don't just remove bad patterns, inject actual personality following [voice-and-soul.md](references/voice-and-soul.md) (signs of soulless writing, how to add voice, before/after).
6. **Do a final anti-AI pass** — ask yourself: "What makes the below so obviously AI generated?" Answer briefly with any remaining tells, then revise one more time.

## Pattern checklist

The 29 patterns, grouped. Detail and examples for each live in [patterns.md](references/patterns.md).

**Content (1-6):** significance/legacy inflation ("pivotal moment", "evolving landscape") · notability and media-coverage claims · superficial -ing analyses ("highlighting...", "showcasing...") · promotional language ("vibrant", "nestled", "breathtaking") · vague attributions ("experts argue") · formulaic "Challenges and Future Prospects" sections

**Language and grammar (7-13):** AI vocabulary (delve, tapestry, testament, underscore...) · copula avoidance ("serves as" → "is") · negative parallelisms ("not just X, but Y") and tailing negations · rule-of-three overuse · synonym cycling · false ranges ("from X to Y") · passive voice and subjectless fragments

**Style (14-19):** em dash overuse · boldface overuse · inline-header vertical lists · title case in headings · emojis · curly quotes

**Communication (20-22):** chat artifacts ("I hope this helps!") · knowledge-cutoff disclaimers · sycophantic tone

**Filler and hedging (23-29):** filler phrases ("in order to") · excessive hedging · generic positive conclusions · hyphenated word-pair overuse · persuasive authority tropes ("at its core") · signposting ("let's dive in") · fragmented headers

## Process

1. Read the input text carefully (use `Read` if it's a file).
2. Identify all instances of the patterns from [patterns.md](references/patterns.md).
3. Rewrite each problematic section.
4. Ensure the revised text:
   - Sounds natural when read aloud
   - Varies sentence structure naturally
   - Uses specific details over vague claims
   - Maintains appropriate tone for context
   - Uses simple constructions (is/are/has) where appropriate
5. Present a draft humanized version.
6. Prompt yourself: "What makes the below so obviously AI generated?"
7. Answer briefly with the remaining tells (if any).
8. Prompt yourself: "Now make it not obviously AI generated."
9. Present the final version (revised after the audit).
10. If the text came from a file, apply the edit with `Edit` (targeted) or `Write` (full rewrite) and show the user what changed.

First time running this process, or unsure what the output should look like? Read [full-example.md](references/full-example.md) — a complete pass from AI-sounding input through draft, self-audit, and final rewrite.

## Output Format

Provide:
1. Draft rewrite
2. "What makes the below so obviously AI generated?" (brief bullets)
3. Final rewrite
4. A brief summary of changes made (optional, if helpful)

## Attribution

This skill is ported from [blader/humanizer](https://github.com/blader/humanizer) (MIT licensed), which is itself based on [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup. The patterns documented there come from observations of thousands of instances of AI-generated text on Wikipedia.

Original author: Siqi Chen ([@blader](https://github.com/blader)). Original repo: https://github.com/blader/humanizer (version 2.5.1). The 29 patterns, personality/soul section, and full worked example are preserved verbatim from the source (now in `references/`). Original MIT license preserved in the `LICENSE` file alongside this `SKILL.md`.

Key insight from Wikipedia: "LLMs use statistical algorithms to guess what should come next. The result tends toward the most statistically likely result that applies to the widest variety of cases."
