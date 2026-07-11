# Common rules — paid-offer protocol, paid-engine errors, chaining

Contents:
- [Paid-offer protocol](#paid-offer-protocol)
- [Paid-engine errors (fal.ai)](#paid-engine-errors-falai)
- [Compose multiple steps when one pass is not enough](#compose-multiple-steps-when-one-pass-is-not-enough)
- [Repositioning an object already placed in a composite](#repositioning-an-object-already-placed-in-a-composite)

## Paid-offer protocol

The offer is one short sentence, embedded in the result message —
not a separate question that blocks the conversation. **Never mention
the dollar cost to the user** — say «на платном движке», «в pro
качестве», «с лучшей моделью», not «$0.04». The cents-level math is
operator concern, not user concern.

> «Если хочется резче и чтобы кофемашина и бюст не плыли — могу
> переделать на платном движке. Сказать?»

Trigger phrases for offering an upgrade proactively:
- The free output drifted on identity (bust morphed, label garbled,
  fingers/faces wrong) — mention this in the offer.
- The user is iterating on the same image >2 times — quality ceiling
  of the free model is being hit.
- The user asked for «фотореалистично», «резко», «как с фотографии»,
  «детально», «pro», «studio».

Trigger phrases for upgrading immediately after user confirms:
- «да», «давай», «переделай», «хочу резче», «на платном»,
  «офигенный», «yes», «do it», «upgrade», «нанеси».

Do not state the cost in any reply, including the one after a paid
call. The script's stdout has the cost for operator logs; don't echo
it back to the user.

If the same user has already opted into paid in this topic this
session, default to paid for follow-up edits in the same conversation
without re-asking. Reset to free on the next session.

If a single user request fans out to 4+ paid calls (multi-variant
generation, chain of edits), check in before the third call without
naming dollars: «это будет ещё несколько правок на платном — ок?»

## Paid-engine errors (fal.ai)

- `edit_fal.py` / `edit_fal_fill.py` fail with «FAL_KEY not set» →
  surface that to the user clearly: «платный движок сейчас недоступен,
  могу только на бесплатном — качество будет ниже». Don't pretend the
  upgrade option exists when it doesn't.
- `edit_fal.py` / `edit_fal_fill.py` fail with HTTP 402 (balance
  empty) → tell the user «платный движок временно недоступен, пиши
  servitola — пока на бесплатном», then run the free script with
  the same flags. No mention of money or balances.

## Compose multiple steps when one pass is not enough

Some user requests don't fit a single pipeline — chain them and pass
the output of step N as the input of step N+1. Recognise these
patterns up front; do not start with one pass and hope for the best.

Common chains:

- **Clean a label, then place in scene.**
  Run 1: `edit_mflux.py` with prompt "remove all text/labels from
  the pot, keep everything else identical, plain ceramic surface".
  Run 2: `edit_mflux.py` on the cleaned output with the
  scene-placement prompt.
- **Cutout + relight on new background.**
  Run 1: `cutout_rembg.py` → transparent PNG.
  Run 2: `edit_mflux.py` with the cutout PNG as input and
  prompt "place this subject on …, lighting from …".
- **Compose from multiple user images, then localise a tweak.**
  Run 1: `edit_hfspace.py --input A --ref B --ref C` to combine the
  scenes into a single base. Run 2: `edit_inpaint.py` with a bbox on
  the area the user is still unhappy about. Preserves the composed
  frame and only repaints the problem region.
- **Replace meme caption (text) with a different language.**
  Run 1: `edit_mflux.py` "remove the caption text; fill the area
  with matching texture/background; keep illustration identical".
  Run 2: programmatic PIL composite — load the cleaned image, draw
  the new caption with a downloaded font (e.g. Impact, DejaVu
  Sans Bold) plus stroke. This is the only reliable path for
  multi-line text edits because diffusion text rendering breaks at
  >1 short line.
- **Restyle a portrait + new background.**
  If both transformations together degrade quality, do bg first,
  then portrait edit (or vice versa); compare both orders on a
  test sample.

When chaining, name the intermediate files clearly
(`/tmp/<task>_step1_clean.png`, `/tmp/<task>_step2_placed.png`) so
you can iterate on either step without redoing the other.

Tell the user up front you'll run N steps and why ("сначала уберу
надпись, потом поставлю на полку — это две генерации, ~12 минут").
Send only the final result via the bot; don't spam intermediate
files unless the user asks to see the chain.

## Repositioning an object already placed in a composite

The user nudges an object that's already pasted into a flat image
("подвинь ветку выше", "ещё левее") — not a fresh placement. Cut the
object out and capture the clean background **once**, from the version
before any move, then reuse both for every further nudge in that
session:

- **Cutout**: the object as RGBA (alpha keyed off a flat/white canvas,
  or a real mask if the surroundings aren't flat).
- **Clean background**: the same base image with the object's original
  spot restored to what was actually there before it was placed — not
  automatically "fill with white". If the object sat on a genuinely
  blank/white card or canvas, white is correct because that *is* the
  real background. If it sat on a photo (a wall, a room, a shelf), the
  hole must show that photo — pull a version of the background from
  before the object was composited if one exists, otherwise
  reconstruct it with inpainting. A flat-colour patch over a photo
  background reads as an obvious defect.
- **Every further move** = `composite.py` with the *same* cutout onto
  the *same* clean background, at new coordinates (current offset +
  the requested delta). Do not take the last rendered/composited image
  as the new background and cut a rectangle out of it — if the object
  has drifted onto or near a border/frame/other element, a rectangular
  erase there destroys that neighbouring content instead of just the
  moved object, and the damage compounds with every further move.
- Track the running total offset from the original position yourself;
  the user only gives the next relative nudge ("ещё левее на 50"), not
  cumulative coordinates from the start.

Keep `..._cutout.png` and `..._bg_clean.png` around for the whole
editing session (same naming principle as chaining above) instead of
re-deriving them from an already-modified frame.
