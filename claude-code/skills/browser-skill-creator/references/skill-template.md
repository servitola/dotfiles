# Canonical site-skill template

The skeleton every generated site skill follows. Section order matters — it
mirrors order-food / gov-cy / book-doctor-cy / pay-bills-cy, which are
battle-tested. Fill every section; each exists because a real skill failed
without it.

## Contents

1. [Frontmatter](#frontmatter)
2. [Section-by-section skeleton](#section-by-section-skeleton)
3. [Cache file pattern](#cache-file-pattern)
4. [Language conventions](#language-conventions)

## Frontmatter

```yaml
---
name: <kebab-case, task-domain name — order-food, pay-bills-cy>
description: |
  <What it does, 2–4 sentences: which sites, primary vs fallback, that it
  drives the web UI through Playwright MCP, loads the profile from
  ~/.claude-playwright-profiles/<name>, and STOPS one step before the final
  irreversible action — the user confirms themselves. No auto-confirm.>

  <First-run note if applicable: manual login (SMS code in the browser
  window) and one-time cache scrape into <cache>.json.>

  Use when: "<5–10 real trigger phrases in Russian>", "<and in English>",
  "<site names as bare words: Foody, JCC Smart>".

  Do NOT use for: <adjacent tasks that look similar but belong elsewhere,
  with where they actually go>.
---
```

The "STOPS one step before" sentence belongs in the description, not only in
the body — it sets expectations before the skill even loads.

## Section-by-section skeleton

```markdown
# <skill-name>

<One paragraph: which sites it drives, through which Playwright MCP config
(absolute path to the project's .mcp.json), and a pointer to read Hard rules
first if money/medical/government is involved.>

## Hard rules

Numbered, ordered by severity. Rule 1 is always the stop-point rule:

1. Never click the final "<exact button labels in every site language —
   'Place order' / 'Pay' / 'Оформить заказ' / 'Πληρωμή'>". Stop one step
   before. The user confirms in the browser themselves. <Why: spends real
   money / files a signed form / writes to a medical record.>
2. Always print a summary in chat before that final step: <the exact field
   list for this domain — see safety-rules.md per risk class>. Wait for the
   user to read it.
3. No new payment method, no address change, no saved-detail edits without
   explicit user instruction.
4. If the data looks wrong (<domain-specific sanity triggers: price way off
   normal range, wrong account number, name mismatch with passport>) — stop
   and ask, do not "fix" silently.
<5+. Domain extras: emergency triage for medical, one-bill-at-a-time for
payments, never pick the doctor — see safety-rules.md.>

## User context

- Address: <…> (already saved on the site).
- Phone: <…>. Email: <…>.
- <Saved card / subscription / enrolment status — whatever the site holds.>
- Primary site: <X>. Fallback: <Y> (use only when <condition>).
- <What is session-only and never written to disk: card data, medical IDs.>

## Browser profile

Persistent Chromium profile at `~/.claude-playwright-profiles/<name>`. Keeps
<which sessions / cookies>. Do not pass `--isolated` to the MCP — that wipes
the session every run. Do not reuse another skill's profile.

<First-run login handover block — copy from first-run-login.md.>

## First-run setup (one time)

<History/account scrape into the cache file: what to open, what to read,
the JSON schema, and the rule to confirm sensitive numbers with the user
before saving. Skip this section if the site has nothing worth caching.>

## Flow: <primary task> (<primary site>)

1. `cd <project dir>` so the project-scoped MCP loads.
2. Open <URL>. Verify <logged-in indicator / address chip>. If wrong — stop
   and ask.
3. <Steps. Resolve targets via the cache file first, search second,
   confirm ambiguity with the user.>
4. Print the pre-submission summary (fields from Hard rule 2).
5. Say: «Готово. Нажми '<final button>' в окне браузера.» Stop.
6. <Post-confirmation step if any: capture receipt/acknowledgement number,
   save to cache, screenshot.>

## Flow: <fallback site / fallback channel>

<Same shape for the secondary site. If no online path exists — a structured
phone-call script with: verified phone number, best hours to call, and the
exact script in EN/EL/RU like book-doctor-cy Flow G. Never invent
availability or URLs that don't exist.>

## When the user is vague

«<vague trigger>»: list top options from the cache file, ask which one.
Do not pick automatically — <why the choice is personal in this domain>.

## Selector maintenance

<Site tech note: React SPA = selectors rot in months; server-rendered =
more stable.> When a step fails:

1. `browser_snapshot` to dump the accessibility tree.
2. Find the new control by role + accessible name, never by CSS class.
3. Append to SELECTORS.md in this skill directory with the date.
   Do not silently retry — <domain reason: on payment portals a silent
   retry can double-submit>.
4. If the site is down, say so and propose the fallback. Do not loop.

## What this skill does NOT do

- Does not press the final "<button>". Ever.
- Does not <each out-of-scope item from the discovery interview, each with
  where that task actually belongs>.
- Does not store <card numbers / passwords / medical IDs> on disk.
  Credentials live in the browser profile only.
```

## Cache file pattern

Skills with reusable site data keep one JSON cache next to SKILL.md (private
repo) or under `~/.claude/skills/<name>/` (when the skill dir is public but
the data is personal). Conventions:

- `scraped_at` / `updated_at` date at the top — the skill can judge staleness.
- Per-entry sanity anchors (`last_paid_eur`, `avg_total_eur`,
  `order_count`) so Hard rule 4 has numbers to compare against.
- Append-mostly: ask before overwriting an existing entry, confirm new
  sensitive numbers in chat ("yes, save") before writing.
- Account references only. Card numbers, CVV, passwords, beneficiary IDs
  stay out of every file.

Reference schemas: `order-food/favorites.json` (restaurants + usual items),
`pay-bills-cy` accounts.json (billers + references + last-paid anchors),
`gov-cy` account.json (permit type + government IDs the user okayed caching).

## Language conventions

- Triggers: Russian and English both, plus bare site names.
- Body: English prose.
- User-facing messages the skill will say in chat: quoted in Russian —
  «Залогинься в окне браузера (SMS-код), потом скажи 'продолжай'».
- Button labels: every language the site shows (EN/EL/RU for Cyprus sites),
  so the stop-rule matches whatever the page renders.
