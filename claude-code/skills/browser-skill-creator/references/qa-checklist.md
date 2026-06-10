# QA checklist for a generated site skill

Run this before handing the new skill to the user. The pattern is borrowed
from interactive-Playwright QA practice: build an explicit coverage
inventory first, then check against it — ad-hoc spot checks miss exactly the
paths that break in production.

## Contents

1. [Build the QA inventory](#build-the-qa-inventory)
2. [Dry-run the primary flow](#dry-run-the-primary-flow)
3. [Stop-point verification](#stop-point-verification)
4. [Fallback and edge paths](#fallback-and-edge-paths)
5. [Screenshot conventions](#screenshot-conventions)
6. [Document hygiene](#document-hygiene)
7. [Signoff](#signoff)

## Build the QA inventory

Before testing, list in one place:

- Every flow the SKILL.md claims to handle (each "Flow:" section).
- Every stop-point (final buttons, confirmation phrases).
- Every fallback (secondary site, phone script, "site is down" path).
- Every cache read/write the skill performs.
- Every claim the skill's description makes ("loads logged-in profile",
  "stops at checkout", "first run scrapes history").

Each item must map to at least one check below. Anything that appears in the
description but has no check is either untested or shouldn't be claimed.

## Dry-run the primary flow

Execute the primary flow with the generated SKILL.md as the only
instructions (pretend the recon never happened — the skill must stand
alone):

- [ ] Project dir + `.mcp.json` resolve; the MCP launches with the right
      profile (logged-in indicator present, no fresh-browser look).
- [ ] Every step's selector matches the live page (snapshot before each
      action; refs from the current snapshot only).
- [ ] Cache short-circuit works: a request matching a cached entry skips
      search and goes straight to the target.
- [ ] The vague-request path asks instead of auto-picking.
- [ ] Pre-submission summary prints with every required field filled
      (per the risk class's field table) — no invented values, "?" allowed.
- [ ] The flow stops where it says it stops. Walk it right up to the final
      screen and verify the final button was never clicked (check the site:
      no order placed, no form filed).

## Stop-point verification

The single most important check — do it deliberately, not as a side effect:

- [ ] The final button's label in the SKILL.md matches what the live page
      renders, in every language the site can show.
- [ ] The step before the final button is unambiguous: "open the cart" vs
      "click Pay" cannot be confused by a future agent reading the skill.
- [ ] For government/financial flows: the explicit confirmation phrase
      ("да, отправляй") gate is written into the flow, not just the rules.
- [ ] SELECTORS.md marks the final button with its never-click note.

## Fallback and edge paths

- [ ] Logged-out state: the skill detects it (missing indicator) and hands
      over with the Russian login message, rather than typing credentials.
- [ ] Fallback site/channel: at least open it and verify the entry URL and
      first-screen selectors are real. Phone-script fallbacks: verify the
      phone number and the hours claim against the clinic/site page.
- [ ] Site-down behavior: skill says what to do (report + propose retry or
      fallback, two reloads max), not an infinite loop.
- [ ] Selector-breakage path: staleness protocol referenced, SELECTORS.md
      exists with at least the recon-day entries.

## Screenshot conventions

When the generated skill captures evidence (receipts, confirmations) or
emits screenshots for model interpretation:

- [ ] Fixed viewport in `.mcp.json` (e.g. 1280×900) so captures are
      reproducible run-to-run.
- [ ] Screenshots intended for model reading are normalized to CSS pixels
      (`scale: "css"` when capturing via Playwright APIs). On Retina,
      device-pixel screenshots come back 2× — coordinates derived from them
      will not match the page's CSS coordinates if the reply is later used
      for clicking, and the payload doubles in size for no benefit.
- [ ] Prefer viewport screenshots for evidence; full-page captures only as
      secondary debugging artifacts.
- [ ] Receipt/acknowledgement screenshots are taken after the user confirms
      success, with the reference number readable.

## Document hygiene

- [ ] Every template section present (frontmatter, hard rules, user context,
      profile, first-run, flows, vague-request, selector maintenance,
      does-NOT-do).
- [ ] description ≤1024 chars, triggers in RU and EN, "Do NOT use for"
      present.
- [ ] Body in English, user-facing chat lines quoted in Russian, button
      labels in the site's languages.
- [ ] No credentials, card data, or medical IDs anywhere in the skill dir.
- [ ] All file paths absolute; cache file location stated explicitly.
- [ ] SKILL.md under 500 lines (split per-platform flows into references
      if approaching the limit).

## Signoff

Before reporting done, answer explicitly:

- Which inventory items were exercised, and which were intentionally
  skipped (and why — e.g. "fallback site requires login the user hasn't
  done yet; verified entry URL only").
- The negative confirmation: "the final button was never clicked during QA;
  no order/filing/payment was created."
- What the user must do on the first real run (login, cache scrape
  confirmation).
