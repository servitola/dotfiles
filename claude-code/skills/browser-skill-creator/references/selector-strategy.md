# Selector strategy

How generated skills locate and maintain page elements so they survive site
redesigns. Bake these rules into every flow you draft.

## Contents

1. [Snapshot → action → snapshot cycle](#snapshot--action--snapshot-cycle)
2. [Role + accessible name over CSS](#role--accessible-name-over-css)
3. [Staleness protocol](#staleness-protocol)
4. [SELECTORS.md format](#selectorsmd-format)
5. [Site-tech expectations](#site-tech-expectations)

## Snapshot → action → snapshot cycle

The Playwright MCP loop every flow step follows:

1. `browser_snapshot` — dump the accessibility tree, get element refs.
2. Act on a ref from the latest snapshot (click / fill / select).
3. Snapshot again after anything that changes the page: navigation, clicks
   that open modals or menus, tab switches, cart updates, form submits.

Refs are only valid against the snapshot they came from. Acting on a ref
from two snapshots ago is the most common silent-failure mode — the click
lands on the wrong element or nothing.

## Role + accessible name over CSS

Record elements as role + accessible name:

- `button "Place order"`, `combobox "Specialty"`, `link "My orders"`,
  `textbox "Search restaurants"`.

Reasons, in order of how often they bite:

1. SPA frameworks hash CSS classes per build (`css-1x2y3z`) — they rotate on
   every deploy. Role+name survives redesigns as long as the feature exists.
2. The accessibility tree is what `browser_snapshot` returns anyway, so
   role+name selectors are directly actionable without extra lookups.
3. Multi-language sites (EN/EL/RU on Cyprus portals) change the *name* per
   locale — record the name in every language the site renders, and pin the
   profile's language on first login when the site allows it.

Positional selectors ("third button in the row") and text-fragment XPath are
last resorts; if forced into one, flag it in SELECTORS.md as fragile.

## Staleness protocol

When a recorded selector stops matching:

1. Stop the flow — no blind retries. On payment portals a retried click can
   double-submit; on booking forms it can file a duplicate request.
2. `browser_snapshot` the current page.
3. Find the control by role + accessible name in the fresh tree. Check
   whether the site changed the label (common after redesigns and locale
   flips) or moved the control behind a menu.
4. Update SELECTORS.md with the date and the new selector.
5. Resume from the failed step, not from the beginning, unless the page
   state was lost.
6. If the page itself is broken (blank, 504, endless spinner) — report to
   the user and offer the fallback channel. Two failed reloads max.

## SELECTORS.md format

Each generated skill keeps `SELECTORS.md` next to its SKILL.md. Created on
first need, append-only, newest entries on top of each section:

```markdown
# SELECTORS — <site>

## <Page or flow step>

- 2026-06-10 `button "Προσθήκη στο καλάθι"` — add-to-cart on item modal.
  Greek label even with EN locale; EN name "Add to cart" appears only
  half-rendered. Match either.
- 2026-03-02 `button "Add to cart"` — replaced `div.add-btn` (class hash
  rotated after redesign).

## Checkout

- 2026-06-10 `button "Place order"` — FINAL BUTTON, never click (Hard rule 1).
```

Conventions:

- Date first — staleness is judged at a glance.
- One line of context: what broke, what replaced what.
- Mark the final irreversible button explicitly so a future agent scanning
  SELECTORS.md re-learns the stop-point.

## Site-tech expectations

Set maintenance expectations in the generated skill's "Selector maintenance"
section based on what recon showed:

- **React/Vue SPA** (Foody, Bolt Food, Doctoranytime): selectors rot every
  few months; treat breakage as expected, not exceptional.
- **Server-rendered / legacy** (JCC Smart, gov.cy, bank portals): stable for
  years but re-skinned wholesale without notice — when they break, everything
  breaks at once; re-walk the whole flow.
- **Forms behind SSO** (CyLogin, Ariadni): the login page changes
  independently of the service pages; keep login selectors in their own
  SELECTORS.md section.
