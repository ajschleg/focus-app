# FocusSlice — v1 release roadmap

> One line per feature below the tracker; full specs live in their own docs
> (CONCEPT.md, CLASSES.md, ART.md, QUESTS.md, CURRENCY.md, ios/README.md). Update the checklist as statuses
> flip — this is the single place to see distance-to-release.

## Progress to release

- [x] Core focus loop
- [x] Distraction detection
- [x] Phase-end notifications
- [x] Score, XP & the guild ladder
- [x] Quests & coin earning
- [ ] Classes
- [ ] Currency (the spend side)
- [ ] Friends
- [ ] Art

**5 / 9 complete.**

## Features

### Core focus loop — Shipped
Plan a block, focus with the phone down, take the earned break (or skip it
and forfeit the credit), review the score. The skeleton everything else
hangs on.

### Distraction detection — Shipped
Leave-the-app and pickup detection fused into the distraction log, with
lock-vs-leave disambiguation and rest-to-motion pickup arming. Heuristic
knobs still get tuned on device (ios/README.md).

### Phase-end notifications — Shipped
Time-sensitive local notifications so a locked phone hears the end of a
block or break; foreground banners via the delegate; permission warnings on
the plan screen.

### Score, XP & the guild ladder — Shipped
Every block scores 0–100 (distractions, early-quit penalty, break credit),
banks XP, and moves the ten-rank guild ladder (Novice → Paragon) with
promotion rewards and demotion pressure.

### Quests & coin earning — Shipped
The quest board pays focus coins: Hydrate (pre-focus), Clean sweep (opt-in),
Stillness check (mid-block surprise), and Move your body (HealthKit-verified
daily exercise, with the break-prompt walk nudge).

### Classes — Design complete, not started
The passive RPG identity: seven decaying affinity axes fed by the Chronicle
turn how you live into a title (29 classes + the Ascetic epithet) beside
your ladder rank. Spec agreed in CLASSES.md; build order: Chronicle →
ClassEngine (+ §12 tests) → break recap → badge/ⓘ → first-class ceremony,
with the lifestyle quiz last as the ship gate.

### Currency (the spend side) — Design drafted, not started
Coins currently only accumulate. v1 adds the sink that closes the economy:
per-minute earning plus two purchases — Long rest (extend the break) and
Furlough (pre-armed phone window during focus). Spec in CURRENCY.md,
awaiting sign-off.

### Friends — Not started
Needs concept work: what "friends" means here (shared presence? co-focus
blocks? seeing each other's titles?) is undecided. Constraint to honor from
CLASSES.md §13: nothing leaderboard-shaped — the portrait is personal, so
friends should be company, not comparison.

### Art — Not started (style guide ready)
Replace placeholder SF symbols with real artwork: the ten ladder ranks and
the 30 class figures. Style guide, per-class briefs, and an image-model
prompt template are ready in ART.md; the app icon already exists.
