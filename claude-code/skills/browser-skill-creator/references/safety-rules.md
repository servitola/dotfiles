# Safety rules by risk class

The stop-points and gates a generated skill enforces, by what the site can
do to the user. Pick the class in Phase 1 and apply everything listed for it
plus everything from the universal set. When a site spans classes (gov-cy
touches both filings and payments), apply the union.

## Contents

1. [Universal rules (every skill)](#universal-rules-every-skill)
2. [Financial class](#financial-class)
3. [Medical class](#medical-class)
4. [Government / legal class](#government--legal-class)
5. [Low-risk class](#low-risk-class)
6. [Pre-submission summary checklist](#pre-submission-summary-checklist)

## Universal rules (every skill)

These go into every generated skill's Hard rules, regardless of class:

1. **Stop one step before the final button.** Never click "Place order" /
   "Pay" / "Confirm" / "Submit" / "Book" — including its Greek and Russian
   labels («Πληρωμή», «Κράτηση», «Оформить заказ»). The user presses it in
   the browser themselves. List the exact labels recon found.
2. **Print the pre-submission summary in chat first** (fields below) and
   wait for the user to read it. For high-stakes classes require an explicit
   confirmation phrase ("да, отправляй") before even advancing to the final
   screen.
3. **Use only saved details.** No new card, no address change, no
   saved-profile edits without explicit instruction. If nothing is saved —
   stop and ask rather than typing data the user pasted casually in chat.
4. **Sanity-check before the summary.** If anything looks off — stop and
   ask, never "fix" silently. Each class defines its triggers below.
5. **Credentials never touch disk.** Passwords, 2FA codes, card numbers,
   CVV live in the browser profile / user's head only. Cache files hold
   account references at most, and only after the user says "yes, save".
6. **No silent retries** on steps that submit data — a retry can
   double-submit. Selector breakage → staleness protocol, not a re-click.

## Financial class

Sites that move money: delivery checkout, bill portals, top-ups, fines.

- Amount sanity gate: stop and ask when the amount is >1.5× the last known
  amount for the same biller/restaurant (use the cache file's
  `last_paid_eur` / `avg_total_eur` anchors), when the currency is not the
  expected one, or when the bill is marked "estimated".
- One payment at a time, even when the user says "оплати все": summary →
  user confirms → user clicks → capture receipt → next. No bulk-pay buttons,
  no stacked tabs.
- Surface fees the user may not expect: delivery fee that should be €0 on a
  subscription, late-payment surcharges already applied (call them out
  explicitly).
- Unrecognized pending charges (not matching any cached biller) are treated
  as possibly phishing or mis-routed: read aloud, wait for confirmation.
- Installment / payment-plan offers on the final screen: decline by default,
  only accept on explicit instruction.
- 3DS / bank OTP is naturally the user's job — the skill has already stopped.

## Medical class

Sites that touch medical records or book care.

- **Emergency triage before anything else.** Chest pain, stroke signs,
  severe bleeding, breathing difficulty, anaphylaxis, overdose, suicidal
  crisis → refuse the flow, point to 112/199, even if the user insists.
- Free-text that lands in a medical record ("reason for visit" / symptoms):
  draft in chat, get explicit OK on the exact wording, then paste.
- Present 2–5 provider options with language/fee/coverage fields and let the
  user choose — never auto-pick a doctor or collapse to one "best".
- No diagnosis, no triage advice beyond "start with your GP".
- Medical IDs (beneficiary number, ARC) are session-only — ask each time or
  rely on browser autofill; never write them to a file.
- Coverage warnings before booking (e.g. specialist without referral costs
  more) — surface, ask, then proceed.

## Government / legal class

Sites that file signed forms, declarations, applications.

- Explicit confirmation phrase required ("да, отправляй") before the final
  submit — a stronger gate than the silent stop, because a filed declaration
  cannot be un-filed.
- Identity sanity gate: tax/ID number mismatch, name transliteration
  differing from passport, wrong year pre-selected → stop and ask. Wrong
  identifiers on a filing are not typos to fix on the fly.
- Verify prefilled fields against the user's records before accepting; no
  "Accept all" clicks.
- Capture the acknowledgement/reference number after the user submits and
  save it to the skill's cache.
- Online-vs-in-person honesty: when the flow only exists in person, say so
  up front and offer the appointment/email draft fallback. Do not invent
  tracking URLs or booking forms that don't exist.

## Low-risk class

Read-only dashboards, content sites, search/aggregation.

- Universal rules still apply (a "low-risk" site may still have a delete
  button or a newsletter signup that emails the user).
- The stop-point is any state-changing action the user didn't explicitly
  request.

## Pre-submission summary checklist

The summary printed before the final step. Required fields by class — every
field filled, "?" when unknown, never invented:

| Field | Financial | Medical | Government | Low-risk |
|---|---|---|---|---|
| What exactly is being submitted (order / bill / form / booking) | yes | yes | yes | yes |
| Counterparty (restaurant / biller / clinic / department) | yes | yes | yes | yes |
| Line items or key form values | yes | — | yes | if any |
| Total amount + currency + fees | yes | fee + coverage | amount due if any | — |
| Reference / account number (last 4 minimum) | yes | — | yes | — |
| Date/time/period (delivery ETA, appointment slot, tax year, due date) | yes | yes | yes | — |
| Destination details (address, payment card last 4) | yes | clinic address | recipient dept | — |
| Person-specific (doctor name, languages, GeSY coverage) | — | yes | — | — |
| Where the user must click next, verbatim button label | yes | yes | yes | yes |

Close the summary with the handover line, in Russian:
«Готово. Проверь и нажми '<final button>' в окне браузера.» Then stop.
