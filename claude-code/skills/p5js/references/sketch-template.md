# Sketch Template and Structure

## Contents

- [Choosing a Starting Point](#choosing-a-starting-point)
- [Bare HTML Skeleton](#bare-html-skeleton)
- [Implementation Patterns](#implementation-patterns)
- [Instance Mode](#instance-mode)

## Choosing a Starting Point

- **Interactive generative art** (seed exploration, parameter tuning): start from `templates/viewer.html`. Read the template first, keep the fixed sections (seed nav, actions), replace the algorithm and parameter controls. This gives the user seed prev/next/random/jump, parameter sliders with live update, and PNG download — all wired up.
- **Animations, video export, or simple sketches**: use the bare HTML skeleton below.

## Bare HTML Skeleton

Single self-contained HTML file. Structure: globals → `preload()` → `setup()` → `draw()` → helpers → classes → event handlers.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Project Name</title>
  <script>p5.disableFriendlyErrors = true;</script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.11.3/p5.min.js"></script>
  <!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.11.3/addons/p5.sound.min.js"></script> -->
  <!-- <script src="https://unpkg.com/p5.js-svg@1.6.0"></script> -->  <!-- SVG export -->
  <!-- <script src="https://cdn.jsdelivr.net/npm/ccapture.js-npmfixed/build/CCapture.all.min.js"></script> -->  <!-- video capture -->
  <style>
    html, body { margin: 0; padding: 0; overflow: hidden; }
    canvas { display: block; }
  </style>
</head>
<body>
<script>
// === Configuration ===
const CONFIG = {
  seed: 42,
  // ... project-specific params
};

// === Color Palette ===
const PALETTE = {
  bg: '#0a0a0f',
  primary: '#e8d5b7',
  // ...
};

// === Global State ===
let particles = [];

// === Preload (fonts, images, data) ===
function preload() {
  // font = loadFont('...');
}

// === Setup ===
function setup() {
  createCanvas(1920, 1080);
  randomSeed(CONFIG.seed);
  noiseSeed(CONFIG.seed);
  colorMode(HSB, 360, 100, 100, 100);
  // Initialize state...
}

// === Draw Loop ===
function draw() {
  // Render frame...
}

// === Helper Functions ===
// ...

// === Classes ===
class Particle {
  // ...
}

// === Event Handlers ===
function mousePressed() { /* ... */ }
function keyPressed() { /* ... */ }
function windowResized() { resizeCanvas(windowWidth, windowHeight); }
</script>
</body>
</html>
```

## Implementation Patterns

Apply these in every sketch:

- **Seeded randomness**: always `randomSeed()` + `noiseSeed()` for reproducibility — see `core-api.md` § Seeded Random
- **Color mode**: `colorMode(HSB, 360, 100, 100, 100)` for intuitive color control — see `color-systems.md`
- **State separation**: CONFIG for parameters, PALETTE for colors, globals for mutable state
- **Class-based entities**: particles, agents, shapes as classes with `update()` + `display()` methods
- **Offscreen buffers**: `createGraphics()` for layered composition, trails, masks — see `core-api.md` § Offscreen Buffers
- **Export key bindings**: include the `keyPressed()` save/reseed/pause convention — see `export-pipeline.md` § PNG Export
- **Performance flags**: `p5.disableFriendlyErrors = true` before setup, `pixelDensity(1)` inside setup — see `troubleshooting.md` § Performance

## Instance Mode

Global mode pollutes `window`. For production, use instance mode:

```javascript
const sketch = (p) => {
  p.setup = function() {
    p.createCanvas(800, 800);
  };
  p.draw = function() {
    p.background(0);
    p.ellipse(p.mouseX, p.mouseY, 50);
  };
};
new p5(sketch, 'canvas-container');
```

Required when embedding multiple sketches on one page or integrating with frameworks.
