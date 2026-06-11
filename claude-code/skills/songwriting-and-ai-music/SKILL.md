---
name: songwriting-and-ai-music
description: |
  Songwriting craft (structure, rhyme, hooks) and Suno AI music prompts.

  Use when: "напиши песню", "сочини текст песни", "сделай пародию на песню", "промпт для suno", "write a song", "song lyrics", "suno prompt", "parody song"
---

# Songwriting & AI Music Generation

Everything here is a GUIDELINE, not a rule. Art breaks rules on purpose.
Use what serves the song. Ignore what doesn't.

## What do you need?

Write or revise lyrics?
├─ Original song → read [songwriting-craft.md](references/songwriting-craft.md) — structure skeletons, rhyme types, meter, emotional arc, hooks, prosody
└─ Parody / new lyrics over an existing song → read [parody-adaptation.md](references/parody-adaptation.md) — skeleton mapping, syllable/stress fitting, concept work

Generate music with Suno?
├─ Style prompt, metatags, Custom Mode → read [suno-prompts.md](references/suno-prompts.md) — style formula, full metatag catalog, field limits
└─ Pronunciation or vocal delivery problems → read the Phonetic Tricks section of [suno-prompts.md](references/suno-prompts.md) — respelling, delivery control

Load the smallest set of references that fits the task. A full song-from-scratch
run needs craft + suno; a quick prompt fix needs only suno-prompts.md.

## Workflow

1. Write the concept/hook first — what's the emotional core?
2. If adapting an existing song, map its structure (syllables, rhyme, stress)
   following [parody-adaptation.md](references/parody-adaptation.md)
3. Generate raw material — brainstorm freely before structuring
4. Draft lyrics into the structure, applying craft from
   [songwriting-craft.md](references/songwriting-craft.md)
   (structure, rhyme mix, energy mapping, show-don't-tell)
5. Read/sing aloud — catch stumbles, fix meter
6. Build the Suno style description using the formula in
   [suno-prompts.md](references/suno-prompts.md) — paint the dynamic journey
7. Add metatags for performance direction and fix pronunciation risks,
   both per [suno-prompts.md](references/suno-prompts.md)
8. Generate 3-5 variations minimum — treat them like recording takes
9. Pick the best, use Extend/Continue to build on promising sections
10. If something great happens by accident, keep it

EXPECT: ~3-5 generations per 1 good result. Revision is normal.
Style can drift in extensions — restate genre/mood when extending.

## Lessons Learned

- Describing the dynamic ARC in the style field matters way more
  than just listing genres. "Whisper to roar to whisper" gives
  Suno a performance map.
- Keeping some original lines intact in a parody adds recognizability
  and emotional weight — the audience feels the ghost of the original.
- The bridge slot in a song is where you can transform imagery.
  Swap the original's specific references for your theme's metaphors
  while keeping the emotional function (reflection, shift, revelation).
- Monosyllabic word swaps in hooks/tags are the cleanest way to
  maintain rhythm while changing meaning.
- A strong vocal persona description in the style field makes a
  bigger difference than any single metatag.
- Don't be precious about rules. If a line breaks meter but hits
  harder, keep it. The feeling is what matters. Craft serves art,
  not the other way around.
