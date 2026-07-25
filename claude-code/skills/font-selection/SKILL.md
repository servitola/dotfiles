---
name: font-selection
description: |
  Pick a typeface for a specific job — book, newspaper, infographic, logo, invitation,
  screen UI, deck — using Julian Hansen's "So You Need A Typeface" decision tree, then
  ground the pick in what can actually be licensed and shipped: free substitutes,
  pairing partner, CSS stack, Cyrillic coverage.

  Use when: "подбери шрифт", "какой шрифт выбрать", "шрифт для логотипа", "шрифт для книги",
  "шрифт для сайта", "пара шрифтов", "с чем сочетать шрифт", "чем заменить Helvetica",
  "бесплатный аналог шрифта", "choose a typeface", "what font should I use", "font pairing",
  "free alternative to <font>", "pick a font for this landing page".

  Skip for: copying a specific brand's look (popular-web-designs), slide layout and sizes
  (powerpoint), installing font files, generating specimens.
---

# Font Selection

A typeface is chosen for a job, not in the abstract. Start from the job, walk the tree,
then check the pick survives contact with reality (license, script coverage, rendering).

## Intake

Ask only for what the request leaves open — one short message, not an interview:

- **Job**: book · newspaper/long-form · infographic/data · logo/wordmark · invitation/event ·
  screen UI (app, web, dashboard) · deck.
- **Medium**: print, or screen (and if screen: does it need a web font or a system stack?).
- **Constraints**: budget (free only?), Cyrillic or other scripts, variable axes, an existing
  brand face to pair with, a face the user already dislikes.

When the user gives a job and nothing else, pick sensible defaults and say which you assumed.

## Route

Load the smallest set of references that fits the request.

- **Print or editorial job** (book, newspaper, infographic, logo, invitation) → walk the poster's
  tree in [decision-tree.md](references/decision-tree.md), then look the winner up in
  [catalog.md](references/catalog.md).
- **Screen job** (app UI, web, dashboard, code, money figures) → apply
  [screen-ui.md](references/screen-ui.md); the 2010 poster is print-era and under-serves screens.
  Take the licensable option from [catalog.md](references/catalog.md).
- **"What goes with X?"** / two faces already chosen → apply the rules in
  [pairing.md](references/pairing.md).
- **"What can I use instead of X?"** / "X costs too much" → [catalog.md](references/catalog.md);
  every face there has a closest free substitute.

The tree is a poster by Julian Hansen — deliberately witty and deliberately loose. Use it to
get to a strong candidate fast, then defend or replace that candidate with the catalog and the
practical layer. When the tree's answer is unlicensable or wrong for the medium, say so and
name what it stands for ("Bodoni-style high-contrast didone") before offering the substitute.

## Verify the pick

Before answering, check the candidate against what the user can actually do:

- Installed locally? `scripts/font-check.sh "Garamond"` — lists matching families and styles
  installed on this Mac, via fontconfig.
- Licensed for the use? Retail desktop licenses rarely cover webfont embedding or app bundling.
- Script coverage? Most of the poster's faces have partial or no Cyrillic — verify before
  proposing one for Russian text.

## Answer format

Keep it to this shape — a recommendation, not a survey:

```
**Primary:** <face> — <one line, why this job wants it>
**Pairing:** <partner face> for <role> (body / UI / numerals)
**Stack:** font-family: "<face>", <fallback>, <generic>;      ← screen jobs only
**Getting it:** <Adobe Fonts / Google Fonts / foundry + rough cost>
**If that's out of reach:** <free substitute> — <what changes>
**Runner-up:** <face> — <when it would win instead>
```

Name the path taken through the tree in one line when the tree was used ("book → not clueless →
not the comfort champion → everybody loves Garamond → something bigger → Sabon"). It shows the
reasoning and lets the user re-answer one question to get a different result.
