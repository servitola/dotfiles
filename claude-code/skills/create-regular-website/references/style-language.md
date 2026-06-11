# Natural language → `site.yaml` values

A lookup table: the user describes the look they want in plain words —
you translate to concrete CSS color values, fonts, and density. Goal:
pick a reasonable starting point without asking about hex codes, then
iterate based on user reaction.

## Contents

- [Color palettes (whole sets)](#color-palettes-whole-sets)
- [Single-axis tweaks](#single-axis-tweaks-when-a-palette-is-already-chosen)
- [Fonts](#fonts)
- [Hiding / showing sections](#hiding--showing-sections)
- [Languages other than ru / en](#languages-other-than-ru--en)
- ["Like X" style references](#like-x-style-references)
- [When the user is unhappy after a change](#when-the-user-is-unhappy-after-a-change)

## Color palettes (whole sets)

Each palette is `primary-color` + `background` + `text-color`. Apply
the whole set, don't mix.

### Warm / peach
Triggers: "warmer", "softer", "cozy", "homey", "gentle".
```yaml
primary-color: "#e07856"
background: "#fff8f3"
text-color: "#3d2418"
```

### Minimal
Triggers: "minimal", "strict", "white", "like a gallery".
```yaml
primary-color: "#0f172a"
background: "#ffffff"
text-color: "#0f172a"
```

### Green / nature
Triggers: "natural", "green", "like grass", "calm".
```yaml
primary-color: "#16a34a"
background: "#f7fbf3"
text-color: "#1a2e1a"
```

### Deep dark
Triggers: "dark", "night", "Instagram-y", "black".
```yaml
primary-color: "#a78bfa"
background: "#0b0b12"
text-color: "#e5e5ed"
```

### Pink
Triggers: "pink", "girly", "soft pink", "glam".
```yaml
primary-color: "#db2777"
background: "#fff5f9"
text-color: "#3a1226"
```

### Sand
Triggers: "warm", "beige", "boho", "like a photo backdrop".
```yaml
primary-color: "#b45309"
background: "#fdf6ec"
text-color: "#3b2a14"
```

### Sea
Triggers: "sea", "blue", "cool", "fresh".
```yaml
primary-color: "#0284c7"
background: "#f0f9ff"
text-color: "#0b2a45"
```

### Lavender
Triggers: "lavender", "purple", "calm purple".
```yaml
primary-color: "#8b5cf6"
background: "#f8f5ff"
text-color: "#2c1e4a"
```

## Single-axis tweaks (when a palette is already chosen)

| User says | Do |
|---|---|
| "darker" (background) | shift `background` toward `#000`, raise `text-color` brightness |
| "lighter" (background) | shift `background` toward `#fff`, darken `text-color` |
| "brighter" | raise saturation of `primary-color` |
| "softer", "muted" | lower saturation of `primary-color` |
| "more contrast" | push `text-color` and `background` further apart in lightness |
| "more minimal" | set `primary-color` = `text-color` (one color for everything) |

## Fonts

Default is `Inter` — neutral and readable. Change when the user wants
character.

| Trigger | Heading font | Body font |
|---|---|---|
| "classic", "book-like", "with serifs" | `Playfair Display` | `Lora` |
| "modern", "tech" | `Inter` | `Inter` |
| "friendly", "kind" | `Quicksand` | `Nunito` |
| "strict", "architectural" | `IBM Plex Sans` | `IBM Plex Sans` |
| "handwritten", "personal" | `Caveat` | `Inter` |
| "big and bold" | `Bebas Neue` | `Inter` |

All fonts come from Google Fonts. Just write the name into `site.yaml
→ theme → heading-font` / `body-font`. The engine loads them at
build time.

## Hiding / showing sections

"remove the blog", "no contacts", "turn off the gallery" → set the
right key in `site.yaml → sections` to `false`. Files stay; the
section disappears from the site.

## Languages other than ru / en

The default labels are in Russian (`ru`) and English (`en`). For other
languages, either:
1. Translate the relevant labels in
   `engine/src/lib/labels.mjs` for the new language code, or
2. Set `lang: en` in site.yaml as a fallback (works as English UI with
   any user-language content).

## "Like X" style references

If the user references another site ("make it like Lebedev's", "like
this one") — ask for a screenshot or link. Then:
1. Look at the screenshot / open the link.
2. Identify: dark or light, primary color, serif or sans, content
   density.
3. Pick the closest palette above.
4. Show a preview and let them compare.

Don't try to pixel-copy — that is neither their job nor yours. A
similar-in-spirit result is the goal.

## When the user is unhappy after a change

Ask one precise question: "What is off — too bright? Too dark? Too
pink?" Then move *one* parameter. Don't change everything at once,
they will lose track.
