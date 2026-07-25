# Pairing and hierarchy

Two faces is the working default: one with a voice, one that gets out of the way. Three is a
system decision and needs a reason (a mono for data, a script for one line).

Before adding a face, map the roles that already exist — heading, body, label, button, table,
chart, code — and note which face does which. Most "we need a second font" requests are solved by
giving an existing face a level it was not being used at.

## Start inside a superfamily

The lowest-risk pairing is two members of one superfamily: they share skeleton, cap-height,
x-height, spacing and motifs by construction, so the pair cannot clash. IBM Plex (Sans / Serif /
Mono), Source (Sans 3 / Serif 4 / Code), PT (Sans / Serif), Noto, Alegreya (Sans / Serif) all
qualify and are free.

The cost is a slightly quiet result — the contrast has to come from size, weight and case instead
of from character. Move to a cross-family pairing when the design needs a voice the superfamily
cannot produce.

## The rule that does most of the work

**Contrast the class, share the skeleton.** The pair should differ in category — serif vs sans,
display vs text, high-contrast vs low — while agreeing on the things the eye measures:

- **x-height** — the lowercase should look the same size at the same point size. Mismatched
  x-heights make one face look shrunken next to the other. In families with an optical-size axis
  the x-height changes per optical size, so compare display cut against display cut and text
  against text.
- **width and rhythm** — a condensed display face over a wide body face reads as two projects.
- **weight of the stems** — the "colour" of a paragraph should not jump between roles.
- **era and intent** — a 1780 didone with a 2020 UI grotesque needs a deliberate reason.

Two faces from the same historical family (two old-styles, two neo-grotesques) fight instead of
contrasting. Two faces from one superfamily (IBM Plex Sans + Serif, Source Sans + Source Serif,
Alegreya Sans + Alegreya) always agree — safe, and slightly bland by design.

## Pairs that work

Drawn from the poster's own faces, with a free version of each pair:

| Display / heading | Text / body | Reads as | Free version |
|---|---|---|---|
| Futura | Garamond | modernist, gallery, fashion | Jost\* + EB Garamond |
| Bodoni | Franklin Gothic | editorial, magazine cover | Libre Bodoni + Libre Franklin |
| Gotham | Miller | American brand, campaign | Montserrat + Playfair Display |
| Helvetica | Swift | Swiss structure, readable text | Inter + Literata |
| FF Meta | FF Scala | designed, warm, 90s-lineage | Fira Sans + Alegreya |
| Palatino | Optima | classical, invitations, menus | URW Palladio + Lato |
| FF DIN | Minion | technical report, spec sheet | Barlow + Crimson Pro |
| Baskerville | Univers | academic, formal, structured | Libre Baskerville + Archivo |

## Hierarchy without a second face

Before reaching for a second family, spend what one family already gives you: weight (400 vs
700), size, case, colour, letter-spacing on small caps, and italics. A single well-built family
across four levels usually looks more designed than two families across two.

Set the levels as a scale, not as one-off numbers — 1.2× for dense UI, 1.25–1.333× for editorial.

## Sizes to start from

| Role | Print | Screen |
|---|---|---|
| Body text | 9–11 pt, leading 1.35–1.45 | 16–18 px, line-height 1.5–1.65 |
| Long-form measure | 60–75 characters per line | 60–75 characters per line |
| Subhead | 1.25–1.5× body | 1.25–1.5× body |
| Headline | 2–4× body | 2–3× body |
| Caption / legal | 0.8× body, one step darker to compensate | 0.875× body, contrast ≥ 4.5:1 |

Tighten tracking as size grows (headlines want negative tracking); loosen it for caps, small
caps, and light weights on dark backgrounds.

## Common failures, and what to do instead

- Two faces with personality → give one face the personality and let the other be plain.
- A display face used for body text → keep the display face for one or two lines, set the rest
  in its text-optical sibling or a neutral partner.
- Weights 300 and 400 in the same hierarchy → separate levels by at least 300 units of weight.
- Body text under 16 px on the web → start at 16 px and scale up for long reading.
- All-caps paragraphs → use caps for labels of a few words, with added letter-spacing.
- Faux bold and faux italic (the browser synthesising a weight that is not loaded) → load the
  real weights, or restrict the design to what is loaded.
