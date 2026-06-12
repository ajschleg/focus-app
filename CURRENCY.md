# FocusSlice — Currency: the spend side (Draft for Review)

> Status: **draft for review — nothing here is implemented.** Companion to
> CONCEPT.md §5A (the coin economy) and §6 (the break free track). Earning
> exists today — quests (QUESTS.md) and first-arrival promotion rewards
> (`FocusLevel.ladder`) — and `CoinStore` is earn-only; this doc designs the
> sink that closes the loop. All names and prices are draft.

## 1. What coins buy (one line)

**Rest and sanctioned indulgence — never the score.** Focus earns coins;
coins buy longer breaks and pre-planned phone time. The record (score, XP,
ladder, distraction log) is not for sale.

## 2. Design pillars

1. **Self-balancing (CONCEPT.md §5A).** The loop closes: focused minutes
   fund rest and indulgence, which make the next block sustainable. Phone
   use stops being sin and becomes the thing you earned.
2. **Coins never touch the record.** No score erasers, no demotion shields,
   no log edits. The ladder means something because it can't be bought; a
   purchase changes what happens *next*, never what already happened.
3. **Pre-commitment, not forgiveness.** You buy permission *before* the
   act, never absolution after. Planning an indulgence is discipline;
   purchasing forgiveness is a slot machine. Every sink obeys this.
4. **Ignorable (CONCEPT.md §5's dark-pattern line).** A player who never
   spends a coin loses nothing but the conveniences. No gameplay is gated
   behind spending.
5. **Flat, visible prices.** No randomized rewards, no bundles, no decay.
   The shop is a price list, not a casino.

## 3. Income

| Source | Pays | Status |
|---|---|---|
| Quests (QUESTS.md) | 5–30 per quest | Shipped |
| Ladder promotions, first arrival (`FocusLevel.ladder`) | 20–300 | Shipped |
| **Focused minutes** — 1 coin per 5 focused minutes, rounded down | ~10 per 50-min block | Proposed (canon: §5A "earn per focused minute") |
| **Clean-block bonus** — zero distractions, no early quit | +5 | Proposed (stacks with the opt-in Clean sweep quest — the bonus is automatic, the quest is a wager) |
| Streak multiplier (§5A) | — | Deferred post-v1 |

Feel check: a typical 3–4 block day with a quest or two ≈ **40–60 coins**.

## 4. The sinks (two in v1)

### Long rest — buy a longer break

At the break prompt or during the break: **+5 minutes for 10 coins**, up to
+10 minutes per block. Pure rest — the break credit stays capped at the
template's full-break value, so an extension can never mint score (pillar
2); it just buys more sanctioned time away. Mechanically: extends
`breakDuration` and reschedules the break-end notification (cancel +
reschedule — mind BlockNotifier's matured-trigger race).

### Furlough — pre-planned phone time during focus

The §5A signature, built as pre-commitment (pillar 3):

- **Armed on the plan screen** for **25 coins**, one per block. Arming is
  the purchase; it's a plan-time decision, not a mid-block temptation.
- **Invoked during focus** with a deliberately quiet button: opens a
  **2-minute window** in which leaving the app and pickups are not logged
  as distractions. The window starts on invocation and is not pausable.
- **Unused = refunded** at review. An unspent furlough costs nothing, so
  arming one "just in case" is planning, not waste.
- **Voids Clean sweep and the clean-block bonus** — clean means clean — and
  blows an active Stillness check (a furlough is not stillness). The review
  log shows it neutrally: "furlough taken @ 12:30", its own event kind, not
  a distraction.
- The score is untouched: you paid coins instead of points, *in advance*.

Why this isn't an eraser: the pass is bought before the block and shown in
the log after. The score forgives (you paid); the record remembers (it
happened). Retroactive purchases of any kind stay banned (pillar 3).

## 5. Price sheet (draft)

| Purchase | Price | Limit |
|---|---|---|
| Long rest (+5 min break) | 10 | ×2 per block |
| Furlough (2-min phone window in focus) | 25 | 1 armed per block; refunded if unused |

Calibration: a furlough costs roughly half a day's casual income — affordable
weekly, not hourly. Long rest is an easy near-daily treat. Both prices are
single constants, tuned by feel.

## 6. What coins never buy

Recorded so it isn't re-litigated: score, XP, or rank in any form; demotion
shields; edits to the distraction log or Chronicle; quest rerolls or quest
completion; anything class- or affinity-related (CLASSES.md pillar 5 — paid
identity is fake identity); anything randomized (no loot, no gacha).

## 7. Future sinks (post-v1)

The build-a-world hook (CONCEPT.md §5B) is the economy's real endgame sink —
coins as building material. Cosmetics (badge frames, break ambiance) are
possible before that. Both wait: v1 ships exactly the two sinks above so the
economy's *shape* (earn by focus, spend on rest) proves out first.

## 8. Open questions (for Austin)

1. **Should Furlough exist at all?** It's the boldest idea in CONCEPT.md
   §5A, but some players may read any sanctioned phone time as heresy. v1
   could ship Long rest alone and add Furlough behind a later flag.
2. **Arm-at-plan vs. buy-mid-focus.** Pre-arming is purer pre-commitment
   (and the refund removes the sting); a mid-focus purchase is simpler to
   build but puts a shop inside the temple. Drafted as pre-arm.
3. **Rates and prices** — 1/5min income, 10/25 prices, the 2-minute window:
   all feel-tuned constants; sign off after living with them.
4. **Names.** "Long rest" (D&D borrow) and "Furlough" — alts: Extended
   break, Phone pass, Leave pass.
5. **Does the clean-block bonus stacking with Clean sweep feel right**, or
   should the quest absorb the bonus?

## 9. Implementation sketch (when approved)

- `CoinStore.spend(_:) -> Bool` (guarded, no negative balances) beside the
  existing `earn`.
- Prices and income rates in **one table** (`CoinPrices`), the
  ladder/catalog idiom.
- Per-minute income pays out in `enterReview` (single exit point, same as
  XP banking).
- Furlough: an armed flag on the engine; invocation timestamps a window
  that `record(_:)` and `sceneWentToBackground` check before logging; one
  new event kind for the review log; refund in `enterReview` if uninvoked.
- Long rest: extend `breakDuration` + reschedule the notification; UI on
  BreakPromptView/BreakView.
- Nothing touches scoring — the score path stays purchase-blind (pillar 2).
