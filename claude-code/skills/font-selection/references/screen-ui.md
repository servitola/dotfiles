# Screen: app UI, web, dashboards, code

The poster is print-era. On screen the constraints are different: the type is rendered by
someone else's rasteriser at sizes you do not control, it has to load over a network, and it
often has to line numbers up in a column. Pick for those constraints first, taste second.

## Contents

- [Choose by surface](#choose-by-surface)
- [Numerals: the fintech part](#numerals-the-fintech-part)
- [Variable fonts](#variable-fonts)
- [Stacks and loading](#stacks-and-loading)
- [Rendering reality](#rendering-reality)
- [Legibility floor](#legibility-floor)

## Choose by surface

| Surface | What it needs | Strong defaults |
|---|---|---|
| Product UI (app, dashboard) | tall x-height, open apertures, tabular figures, many weights | Inter, IBM Plex Sans, Geist, system stack |
| Marketing site | a voice in the headline, a workhorse in the body | Instrument Serif / Fraunces + Inter · Montserrat + Source Sans 3 |
| Long-form reading | a text-optical serif with a big x-height | Literata, Source Serif 4, Newsreader, Spectral |
| Data-dense tables | narrow, tabular figures, clear `1lI0O` | Inter (tabular), IBM Plex Sans Condensed, Roboto Condensed |
| Code and logs | monospace, tall lowercase, disambiguated glyphs | JetBrains Mono, IBM Plex Mono, SF Mono |
| Native iOS / macOS | matches the platform, free, already installed | SF Pro via `-apple-system` |
| Native Android | same reasoning | Roboto via `system-ui` |

The system stack is a legitimate answer, not a cop-out: zero bytes, zero layout shift, correct
platform rendering, and full script coverage. Choose a webfont when the brand voice is worth the
bytes and the risk.

## Numerals: the fintech part

Money and metrics have rules the poster never covers.

- **Tabular (monospaced) figures** for anything in a column, anything that updates in place, and
  anything being compared — balances, prices, counters. Otherwise the digits jitter as values
  change. CSS: `font-variant-numeric: tabular-nums;` or `font-feature-settings: "tnum";`
- **Proportional figures** for running prose, where even spacing reads better.
- **Lining figures** (all cap-height) for UI and tables; **old-style** figures only in
  book-like prose.
- **Slashed or dotted zero** when digits sit next to letters (IDs, hashes, codes) — a plain `0`
  reads as `O`. Most code faces have it; JetBrains Mono and IBM Plex Mono ship it by default.
- Check that the chosen face actually has `tnum`. Many display and script faces do not, and the
  browser will silently ignore the request.
- Currency symbols, thin spaces as thousands separators, and minus vs hyphen (`−` U+2212) all
  need checking in the real face before ship.

## Variable fonts

One file, a continuous weight axis, smaller total payload than four static cuts. Worth it when
the design uses three or more weights, or wants optical sizing.

- Common axes: `wght`, `wdth`, `opsz` (optical size), `slnt`/`ital`.
- `opsz` is the one people forget: it thickens hairlines and opens spacing at small sizes, which
  is exactly what didones and text serifs need. Inter, Fraunces, Newsreader and Literata expose it.
- Set ranges in `@font-face` (`font-weight: 100 900;`) so the browser subsets correctly.
- Animate weight only when it is cheap and meaningful — it triggers layout on every frame.

## Stacks and loading

```css
@font-face {
  font-family: "Inter";
  src: url("/fonts/inter-var.woff2") format("woff2-variations");
  font-weight: 100 900;
  font-display: swap;        /* text is readable immediately */
  unicode-range: U+0000-00FF, U+0400-04FF;   /* Latin + Cyrillic subsets */
}

:root {
  --font-ui: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-text: "Literata", Georgia, "Times New Roman", serif;
  --font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
}
```

- **Self-host** rather than hotlinking a font CDN: one less third party, no cross-site cache
  benefit any more, and it keeps EU data-protection questions away from the network tab.
- **woff2 only** — every browser that matters supports it.
- **Subset** to the scripts actually used; a full Cyrillic + Latin + Greek face is often 3–4× the
  bytes needed.
- **Preload** the one or two files used above the fold: `<link rel="preload" as="font" crossorigin>`.
- **`font-display: swap`** for body text; `optional` for decorative faces where a swap would be
  worse than not loading at all.
- Match the fallback's metrics (`size-adjust`, `ascent-override`) to keep the swap from shifting
  layout.

## Rendering reality

- macOS renders heavier than Windows; a weight that looks right on a Mac can look thin on
  Windows ClearType. Check both before locking a light weight.
- Hairlines below ~1.5 px disappear at 1× density. Anything didone-ish needs a text cut or a
  minimum size.
- Dark mode makes type look heavier (light-on-dark bleeds). Drop one weight step, or add a touch
  of letter-spacing, for text on dark surfaces.
- Test at the real device pixel ratio, not a zoomed browser window.

## Legibility floor

- Body text starts at 16 px; 14 px is for secondary UI labels, not for reading.
- Contrast at least 4.5:1 for body text and 3:1 for large text (WCAG AA). Light weights lose
  effective contrast — measure the rendered result, not the hex pair.
- Line length 60–75 characters; line-height 1.5–1.65 for body copy.
- Respect the user's font-size setting: size in `rem`, never lock `html { font-size: 14px }`.
- Do not use font weight or style as the only carrier of meaning (errors, required fields).
