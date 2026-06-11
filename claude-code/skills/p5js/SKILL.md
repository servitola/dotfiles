---
name: p5js
description: |
  Build p5.js sketches end to end: generative art, shaders, interactive visualizations, 3D/WebGL scenes, with PNG/GIF/MP4/SVG export.

  Use when: "сделай генеративный арт", "напиши скетч на p5.js", "интерактивная визуализация в браузере", "make a p5.js sketch", "generative art", "creative coding shader"
---

# p5.js Production Pipeline

## When to use

Use when users request: p5.js sketches, creative coding, generative art, interactive visualizations, canvas animations, browser-based visual art, data viz, shader effects, or any p5.js project. Output is a single self-contained HTML file (PNG/GIF/MP4/SVG export optional).

## Prerequisites

Basic sketches need only a browser — the core library loads from a CDN. The optional export pipeline needs Node.js + Puppeteer (headless capture), ffmpeg (MP4 encoding), and Python 3 (local server for fonts/images). Run `bash scripts/setup.sh` to verify which tools are present.

## Creative Standard

This is visual art, not a code exercise. The output must be visually striking on first load — dense, layered, cohesive, with intentional color and at least one detail the user didn't ask for. Before any code, articulate the creative concept and apply the standards from [creative-direction.md](references/creative-direction.md) — creative standard, vision checklist, aesthetic dimensions, variation rules, parameter design philosophy.

## Stack

Single self-contained HTML file per project. No build step.

| Layer | Tool | Purpose |
|-------|------|---------|
| Core | p5.js 1.11.3 (CDN) | Canvas rendering, math, transforms, events |
| 3D | p5.js WebGL mode | 3D geometry, camera, lighting, GLSL shaders |
| Audio | p5.sound.js (CDN) | FFT analysis, amplitude, mic input |
| Export | `saveCanvas()` / `saveGif()` / `saveFrames()` | PNG, GIF, frame sequences |
| Capture | CCapture.js (optional) | Deterministic framerate capture (WebM, GIF) |
| Headless | Puppeteer + Node.js (optional) | Automated high-res rendering, MP4 via ffmpeg |
| SVG | p5.js-svg 1.6.0 (optional) | Vector output for print — requires p5.js 1.x |
| Natural media | p5.brush (optional) | Watercolor, charcoal, pen — requires p5.js 2.x + WEBGL |
| Texture | p5.grain (optional) | Film grain, texture overlays |
| Fonts | Google Fonts / `loadFont()` | Custom typography via OTF/TTF/WOFF2 |

**Version note:** p5.js 1.x (1.11.3) is the default — stable, broadest library compatibility. p5.js 2.x (2.2+) adds `async setup()`, OKLCH/OKLAB, `splineVertex()`, shader `.modify()`, variable fonts — required for p5.brush. See [core-api.md](references/core-api.md) § p5.js 2.0 Changes.

## Pipeline

Every project follows the same 6-stage path. Load the smallest set of references that fits the task — follow one branch, not all of them.

```
CONCEPT → DESIGN → CODE → PREVIEW → EXPORT → VERIFY
```

1. **CONCEPT** — Articulate mood, visual story, color world, shape language, motion vocabulary using the vision checklist in [creative-direction.md](references/creative-direction.md). Identify the one thing that makes this sketch unique.
2. **DESIGN** — Choose mode (table below), canvas size (1920x1080 / 1080x1920 / 1080x1080 / responsive), renderer (`P2D` or `WEBGL`), frame rate (60fps interactive, 30fps ambient, `noLoop()` static), export target, and interaction model. Pick a position on each aesthetic dimension from [creative-direction.md](references/creative-direction.md) § Aesthetic Dimensions.
3. **CODE** — For interactive generative art, start from `templates/viewer.html` (seed nav, parameter sliders, PNG download — read it first, replace the algorithm). Otherwise build the file following the skeleton and implementation patterns in [sketch-template.md](references/sketch-template.md). Load technique references per the decision tree below.
4. **PREVIEW** — Open the HTML in a browser. Local fonts/images need a server: `bash scripts/serve.sh` or `python3 -m http.server`. Verify 60fps in DevTools Performance tab; test at target export resolution.
5. **EXPORT** — Apply the matching method from [export-pipeline.md](references/export-pipeline.md): in-sketch keys for PNG/GIF, `node scripts/export-frames.js` for headless frames, `bash scripts/render.sh sketch.html output.mp4` for video.
6. **VERIFY** — Does the output match the concept? Sharp at target size? Holds frame rate? Colors work on light and dark monitors? Behaves at canvas edges, on resize, after 10 minutes? If it looks generic, return to stage 1.

## Modes

| Mode | Input | Output |
|------|-------|--------|
| **Generative art** | Seed / parameters | Procedural composition (still or animated) |
| **Data visualization** | Dataset / API | Interactive charts, custom data displays |
| **Interactive experience** | None (user drives) | Mouse/keyboard/touch-driven sketch |
| **Animation / motion graphics** | Timeline / storyboard | Timed sequences, kinetic typography |
| **3D scene** | Concept description | WebGL geometry, lighting, camera, materials |
| **Image processing** | Image file(s) | Pixel manipulation, filters, mosaic |
| **Audio-reactive** | Audio file / mic | Sound-driven generative visuals |

## What do you need?

Building visuals?
├─ Noise fields, flow fields, particles, textures, feedback loops → [visual-effects.md](references/visual-effects.md)
├─ Image processing, pixel manipulation, filters → [visual-effects.md](references/visual-effects.md) § Pixel Manipulation
├─ Primitives, curves, vertices, `p5.Vector`, SDFs, masking → [shapes-and-geometry.md](references/shapes-and-geometry.md)
├─ Palettes, gradients, color harmony, blend modes → [color-systems.md](references/color-systems.md)
├─ Motion, easing, springs, state machines, timelines → [animation.md](references/animation.md)
├─ Text, `textToPoints()`, kinetic typography, text masks → [typography.md](references/typography.md)
├─ 3D, camera, lighting, materials, GLSL shaders, framebuffers → [webgl-and-3d.md](references/webgl-and-3d.md)
└─ Canvas setup, draw loop, transforms, layers, composition → [core-api.md](references/core-api.md)

Handling input?
├─ Mouse, keyboard, touch, DOM controls, scroll → [interaction.md](references/interaction.md)
└─ Audio (FFT, amplitude, mic, beat detection) → [interaction.md](references/interaction.md) § Audio Input

Exporting?
├─ PNG / GIF / frame sequence / SVG → [export-pipeline.md](references/export-pipeline.md)
├─ MP4 or headless batch → [export-pipeline.md](references/export-pipeline.md) § Deterministic Capture + `scripts/render.sh`
├─ Multi-scene video → [export-pipeline.md](references/export-pipeline.md) § Per-Clip Architecture
└─ Platform mint (fxhash / Art Blocks) → [export-pipeline.md](references/export-pipeline.md) § fxhash Conventions

Something wrong?
├─ Slow / dropped frames → [troubleshooting.md](references/troubleshooting.md) § Performance
└─ Wrong rendering, fonts, CORS, WebGL, memory → [troubleshooting.md](references/troubleshooting.md) § Common Mistakes

User asked for experimental / unconventional output?
└─ [creative-direction.md](references/creative-direction.md) § Creative Divergence Strategies

## Implementation Rules

Every sketch applies these; the linked reference holds the how:

- `p5.disableFriendlyErrors = true` before setup and `pixelDensity(1)` inside it — FES costs up to 10x; retina overdraws 2x-4x. `Math.*` in hot loops; no `console.log()` or DOM work in `draw()` ([troubleshooting.md](references/troubleshooting.md) § Performance)
- Seed all randomness — `randomSeed()` + `noiseSeed()`; same seed, same output ([core-api.md](references/core-api.md) § Seeded Random)
- `colorMode(HSB, 360, 100, 100, 100)` with a designed 3-7 color palette — derive variations procedurally instead of hardcoding RGB ([color-systems.md](references/color-systems.md))
- Layer with `createGraphics()` buffers — flat single-pass rendering looks flat ([core-api.md](references/core-api.md) § Offscreen Buffers)
- Multi-octave fBM or domain warping instead of raw `noise()` — raw Perlin reads as smooth blobs ([visual-effects.md](references/visual-effects.md) § Noise)
- For thousands of elements, batch with `beginShape(POINTS)` or pixel buffers instead of per-element draw calls ([troubleshooting.md](references/troubleshooting.md) § Solutions)
- Export key bindings `s`/`g`/`r`/space in `keyPressed()` ([export-pipeline.md](references/export-pipeline.md) § PNG Export)
- Headless video capture requires `noLoop()` + `window._p5Ready` — otherwise frames skip or duplicate ([export-pipeline.md](references/export-pipeline.md) § Deterministic Capture)
- WEBGL mode: center origin, inverted Y, `push()`/`pop()` discipline ([webgl-and-3d.md](references/webgl-and-3d.md) § Mode Gotchas)
- Embedding multiple sketches or framework integration → instance mode ([sketch-template.md](references/sketch-template.md) § Instance Mode)

Performance budgets (frame rate, particle counts, per-pixel costs, file size): [troubleshooting.md](references/troubleshooting.md) § Frame Rate Targets and § Capacity Targets.

## Agent Workflow

1. Write the single self-contained HTML file
2. `open sketch.html` (macOS) / `xdg-open sketch.html` (Linux); local assets need `python3 -m http.server 8080`
3. For PNG/GIF, add the `keyPressed()` shortcuts and tell the user which key to press
4. Headless export: `node scripts/export-frames.js sketch.html --frames 300` (sketch uses `noLoop()` + `_p5Ready`)
5. MP4: `bash scripts/render.sh sketch.html output.mp4 --duration 30`
6. Iterate: edit the HTML, user refreshes the browser
