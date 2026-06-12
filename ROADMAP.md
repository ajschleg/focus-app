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
- [ ] Art

**5 / 8 complete.**

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

### Classes — In progress (core shipped; quiz remains)
The passive RPG identity: seven decaying affinity axes fed by the Chronicle
turn how you live into a title (29 classes + the Ascetic epithet) beside
your ladder rank. Shipped: Chronicle, ClassEngine with the 18-test §12
suite, break recap, badge + ⓘ receipts, first-class ceremony, shift card.
Remaining: the lifestyle quiz (deliberately last — the ship gate) and the
level half of the ⓘ popover (CLASSES.md §10 #11).

### Currency (the spend side) — Design complete, not started
Coins currently only accumulate. v1 adds per-minute earning and two sinks:
Long rest (buy a longer break) and the Courtyard — a code-drawn place built
fixture by fixture, CONCEPT.md §5B at its smallest size. Spec in
CURRENCY.md; prices and fixture names still draft.

## Cut from v1

### Friends — Deferred, possibly permanently
Dropped (June 2026): a real friend system means accounts, a server, push
infrastructure, moderation, and the end of the "stays on your phone" story
the other features lean on — the biggest feature in the app, before the
single-player loop has proven itself. Revisit only if the app sells well,
and then from the cheap end first: share cards and SharePlay co-focus
(borrowing the phone's existing social graph — company, not comparison,
per CLASSES.md §13) before any persistent friend graph (CloudKit sharing,
then a backend, in that order).

### Art — Not started (style guide ready)
Replace placeholder SF symbols with real artwork: the ten ladder ranks and
the 30 class figures. Style guide, per-class briefs, and an image-model
prompt template are ready in ART.md; the app icon already exists.
