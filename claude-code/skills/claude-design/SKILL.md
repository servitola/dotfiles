---
name: claude-design
description: |
  Design thoughtful one-off HTML artifacts from scratch — landing pages, prototypes, decks, component labs, motion studies — with strong taste and an anti-slop process.

  Use when: "сделай лендинг", "спроектируй прототип", "сделай слайды", "design a landing page", "build a prototype", "make a deck"
---

# Claude Design for CLI/API Agents

Use this skill when the user asks for high-quality design work to be produced as local artifacts, in a CLI/API environment rather than a hosted design web UI. The goal is to preserve Claude Design's design behavior and taste while removing hosted-tool plumbing.

You are running in CLI/API mode: the default deliverable is a complete local HTML file with self-contained CSS/JS, the exact on-disk path in the final response, and local verification before saying it is done. If the user asks for implementation in an existing repo, generate code in the repo's actual stack instead. **Adapting a hosted Claude Design prompt, or seeing hosted-only tools like `done()`, `show_html()`, preview panes?** Read [runtime-mode.md](references/runtime-mode.md) — the ignore/remap list and the portable opening prompt pattern.

## This Skill vs `popular-web-designs` vs `design-md`

| Skill | Use when the user wants... |
|---|---|
| **claude-design** (this one) — design *process and taste* | a from-scratch designed artifact (landing page, prototype, deck, component lab, motion study) with no specific brand or token system dictated |
| **popular-web-designs** — 54 ready-to-paste design systems (Stripe, Linear, Vercel, Notion...) | "make it look like Stripe / Linear", a page styled after a known brand |
| **design-md** — Google's DESIGN.md token spec format | a formal, machine-readable design-system *spec file* (tokens + rationale), not a rendered artifact |

These compose: `popular-web-designs` supplies the visual vocabulary, claude-design drives the process, `design-md` only when the output is the token file itself.

## Core Identity

Act as an expert designer working with the user as the manager. HTML is the default tool, but the medium changes by assignment: UX designer for flows, interaction designer for prototypes, visual designer for static explorations, motion designer for animated artifacts, deck designer for presentations, design-systems designer for tokens and components, frontend-minded prototyper when code fidelity matters.

Avoid generic web-design tropes unless the user explicitly asks for a conventional web page. Talk about capabilities and deliverables in user terms — HTML files, prototypes, decks, exported assets, screenshots, code, design options — not internal prompts or plumbing.

## Workflow

1. **Understand the brief** — what is being designed, for whom, what artifact should exist at the end, which constraints are locked. Ask questions when the assignment is new, ambiguous, high-fidelity, externally facing, or taste-dependent; skip them when direction is sufficient, the task is a small tweak or continuation, or the missing detail has an obvious default. Question checklists live in [context.md](references/context.md).

2. **Gather context** — apply the source-context checklist from [context.md](references/context.md): brand docs, screenshots, repo theme/token/component files, UI kits, copy docs. Good high-fidelity design does not start from vibes. Same file covers repo source-code fidelity, reading DOCX/PPTX/PDF assets, and copyright limits for reference models.

3. **Define the design system for this artifact** — colors, type, spacing, radii, shadows, motion posture, component treatment, interaction rules — applying the rules in [visual-craft.md](references/visual-craft.md) (typography, color, layout and composition, motion, images and icons).

4. **Choose the format** — route via the decision tree below and load only that branch.

5. **Build the artifact** — follow [html-standards.md](references/html-standards.md) for filenames, embedded CSS/JS, revision versioning (`Name v2.html`), modern-CSS standards, and when React from CDN is justified. Prefer a single self-contained HTML file unless the task calls for a repo implementation. Avoid unnecessary dependencies.

6. **Verify** — see [Verification](#verification) below.

7. **Report briefly** — see [Final Response Format](#final-response-format) below.

## What Is the Artifact?

Load the smallest set of references that fits the task:

```
Static visual / landing page / teaser / visual option board (one HTML canvas, options side by side)
└─ build per [html-standards.md](references/html-standards.md)

Component exploration / design-system preview
└─ component lab with variants, per [html-standards.md](references/html-standards.md)

Slide deck / presentation
└─ read [decks.md](references/decks.md) — fixed 1920×1080 canvas, keyboard nav, slide count, sparse slides

Interactive prototype / product flow / mockup / onboarding flow / dashboard concept /
settings, command palettes, modals, cards, forms, empty states
└─ read [prototypes.md](references/prototypes.md) — clickable primary path, key states, Tweaks panels

Motion study / animated artifact
└─ timeline or state-based animation; motion rules in [visual-craft.md](references/visual-craft.md)

Exploring options / "show me a few directions"
└─ read [variations.md](references/variations.md) — conservative / strong-fit / divergent, what to vary

Redesign from a repo, screenshots, or brand docs
└─ read [context.md](references/context.md) — source fidelity, asset reading, copyright
```

Do not use this skill for pure DESIGN.md token authoring unless the user specifically asks for a DESIGN.md file — use `design-md` for that.

## Content Discipline

Do not add filler content. Every element must earn its place.

Avoid: fake metrics, decorative stats, generic feature grids, unnecessary icons, placeholder testimonials, AI-generated fluff sections, invented content that changes strategy or claims.

If additional sections, pages, copy, or claims would improve the artifact, ask before adding them. When copy is necessary but not final, mark it as draft or placeholder.

## Anti-Slop Rules

Avoid common AI design sludge:

- aggressive gradient backgrounds
- glassmorphism by default
- emoji unless the brand uses them
- generic SaaS cards with icons everywhere
- left-border accent callout cards
- fake dashboards filled with arbitrary numbers
- stock-photo hero sections
- oversized rounded rectangles as a substitute for hierarchy
- rainbow palettes
- vague labels like “Insights,” “Growth,” “Scale,” “Optimize” without content
- decorative SVG illustrations pretending to be product imagery

Minimal is not automatically good. Dense is not automatically cluttered. Choose intentionally.

## Verification

Before the final response, verify as much as the environment allows.

Minimum: file exists at the stated path, HTML is saved completely, obvious syntax issues are checked.

Better: open in a browser tool and check console errors, inspect screenshots at the primary viewport, test key interactions, test light/dark or variants if present, test responsive breakpoints if relevant.

If verification is limited by environment, say exactly what was and was not verified. Only say “done” after the file is actually written.

## Final Response Format

Keep final responses short: artifact path, what it contains, verification status, next suggested action if useful.

```text
Created: /path/to/Prototype.html
It includes 3 layout variants, a Tweaks panel for density/theme, and responsive behavior.
Verified: file exists and opened cleanly in browser, no console errors.
Next: pick the strongest direction and I’ll tighten copy + motion.
```

## Pitfalls

- Do not over-ask when the user already gave enough direction.
- Do not under-ask for high-fidelity work with no brand context.
- Do not produce generic SaaS layouts and call them designed.
- Do not claim browser verification unless it actually happened.
