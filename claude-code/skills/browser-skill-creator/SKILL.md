---
name: browser-skill-creator
description: |
  Creates site-specific browser-automation skills that drive real websites
  via Playwright MCP: discovery interview, persistent logged-in profile in
  ~/.claude-playwright-profiles/<name>, recorded role+name selectors, then
  a SKILL.md from the proven template (always stops one step before final
  confirmation / payment).

  Use when: "сделай скилл для сайта", "автоматизируй сайт", "скилл для
  браузера", "make a browser skill for site", "automate this website",
  "site automation skill".

  Do NOT use for: skills without a website (skill-master), one-off browser
  tasks (drive Playwright MCP directly), API integrations (curl, no browser).
---

# browser-skill-creator

Generates a new site-specific skill the same way order-food / gov-cy /
book-doctor-cy / pay-bills-cy were built. The output is a skill that drives a
real website through Playwright MCP with a persistent logged-in profile, and
always stops one step before any irreversible action — the user presses the
final button themselves.

This is a procedural skill: each phase feeds the next. Recon before drafting,
drafting before QA.

Partial use: updating only the selectors of an existing site skill → read
[selector-strategy.md](references/selector-strategy.md) and skip Phases 1, 3–5.

## Phase 1 — Discovery interview

Ask the user (in their language, usually Russian) and record the answers:

1. **Site + task**: which site(s), what the skill should accomplish, primary
   site vs fallback site. One skill = one task domain (delivery ≠ groceries).
2. **Risk class** — drives which safety gates apply, per
   [safety-rules.md](references/safety-rules.md) (financial / medical /
   government / low-risk; stop-points and pre-submission summary fields):
   does the flow spend money, touch medical records, file signed government
   forms, or just read/fill harmless data?
3. **User context**: address, phone, email, saved card / account numbers the
   site already knows. What is allowed to be cached on disk and what is
   session-only (card numbers, medical IDs — never on disk).
4. **Profile name**: short noun for `~/.claude-playwright-profiles/<name>`
   (food, gov, doctor, bills, …). One profile per skill — never shared.
5. **Trigger phrases**: 5–10 real phrases in Russian AND English the user
   would actually say.
6. **Out of scope**: what the skill should refuse (becomes the "What this
   skill does NOT do" section).

Checkpoint: all six answers captured before opening a browser.

## Phase 2 — Site recon (live walk-through)

1. Set up the project-scoped `.mcp.json`, the profile directory, and the
   first login following [first-run-login.md](references/first-run-login.md)
   (MCP config shape, 2FA handover to the user, session persistence rules).
2. Walk the entire target flow once in the real browser, stopping before the
   final irreversible step. Use the snapshot → action → snapshot cycle and
   record every control by role + accessible name, following
   [selector-strategy.md](references/selector-strategy.md).
3. Note: which steps need login, where the site flips language, what the
   final button is literally labeled (in every language the site uses),
   what data the site already has saved (address chip, card, account refs).
4. If the site has user history worth caching (past orders, saved billers,
   referrals) — design the cache file schema now (favorites.json /
   accounts.json pattern, see template).
5. Write the first dated entries into the new skill's `SELECTORS.md`.

Checkpoint: flow walked end-to-end minus the final click; selectors recorded.

## Phase 3 — Draft the skill

1. Create the skill directory. Skills with personal data (address, phone,
   account refs) go to `~/projects/dotfiles_private/claude-code/skills/<name>/`
   — same place as order-food and gov-cy. Generic ones may go to the public
   `~/projects/dotfiles/claude-code/skills/`.
2. Write SKILL.md by filling every section of
   [skill-template.md](references/skill-template.md) with the Phase 1–2
   findings — frontmatter, hard rules, user context, browser profile,
   first-run, flows, vague-request handling, selector maintenance,
   does-NOT-do. Skip no section: each one exists because a real skill broke
   without it.
3. Apply the risk-class gates from
   [safety-rules.md](references/safety-rules.md) to every flow's final step.
4. Language: triggers RU + EN; body in English prose; user-facing messages
   quoted in Russian («Залогинься в окне браузера…») — same mix as order-food.

Checkpoint: every template section filled, risk-class gates applied to every flow.

## Phase 4 — QA the generated skill

Run the pre-signoff inventory from
[qa-checklist.md](references/qa-checklist.md): dry-run the primary flow with
the new skill's instructions, verify every stop-point, every fallback path,
and the screenshot conventions. Fix the draft until every checklist item
passes.

Checkpoint: all qa-checklist items pass.

## Phase 5 — Validate

1. Self-check against skill-master conventions: description ≤1024 chars with
   "Use when:", SKILL.md focused and under 500 lines, positive instructions,
   at most one emphasis word.
2. Run: `Use skill-checker subagent to validate the skill at {path}`. Fix
   findings, re-run until clean.
3. Hand over to the user: skill path, profile path, what the first real run
   will ask of them (login + cache scrape), and a reminder that the final
   button is always theirs.
