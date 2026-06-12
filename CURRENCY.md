# FocusSlice — Currency: the spend side (Draft for Review)

> Status: **design agreed in direction; prices, names, and the fixture
> catalog are draft.** Companion to CONCEPT.md §5A (the coin economy), §5B
> (build-a-world), and §6 (break design). Earning exists today — quests
> (QUESTS.md) and first-arrival promotion rewards (`FocusLevel.ladder`) —
> and `CoinStore` is earn-only; this doc designs the sink side.

## 1. What coins buy (one line)

**Rest and a place — never the score, never the self.** Focus earns coins;
coins buy longer breaks and build the Courtyard. The record is not for
sale, and neither is a better you.

## 2. Design pillars

1. **Self-balancing (CONCEPT.md §5A).** The loop closes: focused minutes
   fund rest and a growing place, which make the next block worth sitting
   down for.
2. **Coins never touch the record.** No score erasers, no demotion shields,
   no log or Chronicle edits. A purchase changes what happens *next*, never
   what already happened.
3. **The world, not the self.** The player character *is the user*: score,
   XP, ladder, and class all measure a real person's real behavior, so any
   purchasable boost to them is counterfeit by definition. Coins only ever
   build the world around the player — they never upgrade the player. (This
   is what ruled out stat-boosting equipment.)
4. **Ignorable (CONCEPT.md §5's dark-pattern line).** A player who never
   spends a coin loses nothing but the scenery. Nothing gameplay-critical
   is gated behind spending, and no sink ever interrupts.
5. **Flat, visible prices.** No randomized rewards, no bundles, no limited
   offers. The shop is a price list, not a casino.

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

### Long rest — buy a longer break (consumable)

At the break prompt or during the break: **+5 minutes for 10 coins**, up to
+10 minutes per block. Pure rest — the break credit stays capped at the
template's full-break value, so an extension can never mint score (pillar
2); it just buys more sanctioned time away. Mechanically: extends
`breakDuration` and reschedules the break-end notification (cancel +
reschedule — mind BlockNotifier's matured-trigger race).

### The Courtyard — coins become a place (permanent)

CONCEPT.md §5B's build-a-world hook at its smallest healthy size: **one
place, code-drawn, slot-based.** The courtyard of your guild hall *(name
draft — alts: the Grove, the Garden)*, a single scene that fills in,
fixture by purchased fixture, as the weeks of focus accumulate.

- **Code-drawn, zero image assets.** A parametric SwiftUI scene in ART.md's
  family — flat shapes, ink-line feel, one accent color (the level tint),
  light/dark aware — per the `make-app-icon.swift` precedent. Visuals can
  be upgraded to real illustration later without touching mechanics.
- **Slots, not a sandbox.** The scene has fixed anchor points that fill as
  fixtures are bought. No drag-and-drop editor — that's the scope-killer in
  village builders, and arrangement isn't the fantasy; accumulation is.
- **Yours, specifically.** Each fixture's rendering varies slightly,
  seeded by its purchase date — your tree is not anyone else's tree.
- **It only grows.** Never wilts, never decays, no timers, no FOMO, never
  interrupts (pillar 4). The Courtyard is accumulated focus made visible —
  XP you can sit in.
- **Surfacing:** its own screen, one tap off the plan screen. v1 keeps it
  one glance deep.
- **Persistence:** purchased fixture IDs + dates, local like everything.
- **Future hooks:** classes shape the catalog (the Druid's rare seeds, the
  Blacksmith's anvil — CLASSES.md §13), and if the full world ever ships,
  the Courtyard was its first acre.

**Fixture catalog (names & prices all draft):**

| Fixture | Price | | Fixture | Price |
|---|---|---|---|---|
| Stone path | 20 | | Tree | 80 |
| Moss rock | 25 | | Herb patch | 90 |
| Flower bed | 30 | | Wind chime | 100 |
| Bench | 40 | | Vegetable plot | 120 |
| Lantern | 50 | | Koi pond | 150 |
| Birdbath | 60 | | Evening bell | 200 |
| | | | Fountain | 250 |
| | | | Guild banner | 300 |

≈ 1,500 coins to complete at draft prices — several weeks of ordinary play,
with promotion windfalls (20–300) mapping naturally onto the grand fixtures.

## 5. Price sheet (draft)

| Purchase | Price | Limit |
|---|---|---|
| Long rest (+5 min break) | 10 | ×2 per block |
| Courtyard fixtures | 20–300 | one-time each |

Long rest is the recurring small spend; the Courtyard is the aspirational
large one. Both live in single price tables, tuned by feel.

## 6. What coins never buy

Recorded so it isn't re-litigated: score, XP, or rank in any form; demotion
shields; edits to the distraction log or Chronicle; quest rerolls or quest
completion; anything class- or affinity-related (CLASSES.md pillar 5 — paid
identity is fake identity); **boosts to the self** — equipment, multipliers,
or anything that changes scoring, earning rates, or detection (pillar 3);
anything retroactive (you buy before the act, never absolution after);
anything randomized (no loot, no gacha).

## 7. Cut: Furlough (and why)

A pre-paid "sanctioned phone window during focus" was drafted and cut. In
an observation-only app the score already *is* the price of phone use — a
furlough is score insurance with extra steps, and the rational user skips
the counter and eats the 4 points. Purchasable phone time only has real
value when there's enforcement to unlock — the dock (CONCEPT.md §7) or app
shielding (§9, v2+). Parked behind that precondition, not deleted.

## 8. Future sinks (post-v1)

The world beyond the Courtyard (§5B) as the endgame sink; cosmetics
(badge frames, break ambiance) possibly before that; Furlough if
enforcement ever exists (§7 above). v1 ships exactly two sinks so the
economy's shape — earn by focus, spend on rest and place — proves out
first.

## 9. Open questions (for Austin)

1. **Rates and prices** — 1 coin/5 min income, Long rest at 10, the 20–300
   catalog: all feel-tuned constants; sign off after living with them.
2. **Names** — the Courtyard (alts: Grove, Garden) and every fixture name.
3. **Catalog size** — 14 fixtures drafted; right v1 size? (Slots in the
   scene should slightly exceed launch fixtures so it never looks "done".)
4. **Courtyard surfacing** — its own screen (drafted) vs. a living strip on
   the plan screen itself?
5. **Clean-bonus stacking** with Clean sweep — keep both, or fold one out?

## 10. Implementation sketch (when approved)

- `CoinStore.spend(_:) -> Bool` (guarded, no negative balance) beside
  `earn`.
- The one-table idiom, twice: `CoinPrices` (income rates + Long rest) and
  `FixtureCatalog` (id, name, price, anchor slot, draw routine).
- Per-minute income pays out in `enterReview` (single exit point, same as
  XP banking).
- `CourtyardStore` (purchased fixtures, persisted) + `CourtyardView` (the
  parametric scene; per-fixture seeded variation).
- Long rest: extend `breakDuration` + reschedule the notification; buttons
  on BreakPromptView/BreakView.
- Nothing touches scoring — the score path stays purchase-blind (pillar 2).
