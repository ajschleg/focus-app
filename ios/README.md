# FocusSlice — v1 vertical slice

A deliberately thin, ugly-on-purpose prototype to validate the **one risky thing**
in CONCEPT.md: can we detect distraction well enough (within Apple's privacy
limits, §3) for the core loop to feel *honest*? Everything else — the full reward
economy, hard enforcement — is intentionally left out.

What it does: **Plan** (pick a length) → **Focus** (countdown + live distraction
counts) → **Break prompt** (the earned break is offered — take it or skip it
and forfeit the credit) → **Break** (timer that earns credit toward the score)
→ **Review** (focused time, distraction log, a toy score).

Phase endings are announced with **local notifications** (`BlockNotifier`), so
a locked phone hears "focus block complete" / "break's over". End times are
known when each phase starts, so the notification is scheduled up front and
cancelled if the phase ends *early* in-app (a natural finish leaves the
just-matured trigger alone — cancelling there races the delivery daemon and
can swallow the banner). Banners are presented even while the app is
foreground (the notifier is the center's delegate), so the chime works the
same whether the phone was locked or propped up on the desk. They're marked
**Time Sensitive** (entitlement in `project.yml`) so an iOS Focus/DND mode
doesn't silently eat them. Permission is requested once at launch; if alerts
are denied — or authorized but muted (Deliver Quietly / Lock Screen delivery
off) — the plan screen says so and links to Settings. Stale notifications
from a force-quit session are swept at launch so they can't fire later and
announce a block that no longer exists.

Ending focus early shortens the break in proportion to how much of the block you
completed (focus half the block → half the break), and finishing the break folds
credit into the 0–100 score — so a clean block plus a real break is the only path
to 100 (CONCEPT.md §5: reward proper breaks, not just grinding).

Each block's final score is banked as **XP** when it reaches review
(`ExperienceStore`, persisted in `UserDefaults`) — the first sliver of the
reward economy (CONCEPT.md §5).

On top of XP sits the **guild ladder** (CONCEPT.md §5D, in the spirit of
Apex/Siege ranked): ten levels (Novice → Paragon), each with a name,
placeholder artwork, an app-wide tint, a per-block target score, and
promotion/demotion rules. Score at-or-above the target `winsToPromote` times
to climb; fall below it `missesToDemote` times to drop a level (level 1 is
the floor; counters reset on any level change, and a full winning streak at
the top level "holds the title" — it wipes both counters so slips can't
ratchet toward an inevitable demotion). Climbing gets harder as you rise — targets go 50 → 92
and the required win streak 2 → 6. First-time promotions pay focus coins
(20 → 300, paid for the *destination* level); re-reaching a level after a
demotion pays nothing, so bouncing can't farm coins. **Every knob lives in one table: `FocusLevel.ladder` in `Levels.swift`.**
The current level colors the entire app — controls via `.tint` at the root,
plus a background wash of the level color (a gradient over the system
background, so light/dark mode contrast holds) that cross-fades on
promotion or demotion. The review screen shows the ladder's verdict on each
block.

**Focus coins** (CONCEPT.md §5A) are earned by completing **quests**. `Quest`
is a base class — subclass it, override the lifecycle hooks (`focusStarted`,
`focusTicked`, `distractionRecorded`, `blockFinished`, `workoutLogged`), and
call `complete()` / `fail()`; `QuestBoard` relays the engine's published
state into those hooks and pays into `CoinStore` on completion, so new quests
never touch block logic. The catalog — every quest's trigger, reward, and
affinity — lives in `QUESTS.md` at the repo root. Four starter quests, one
per pattern:

- **Hydrate** (pre-focus prompt, self-report) — pops as a sheet when you tap
  "Start focus": Done pays +5 and the block starts either way (skipped offers
  carry over and prompt again next block). Not shown on the quest board.
- **Clean sweep** (menu, auto, opt-in) — tap Accept on the quest board, then
  finish that block with zero distractions and no early quit, +25. Without
  accepting it the quest sits dormant: nothing is judged, won, or lost.
- **Stillness check** (mid-block surprise, auto) — springs at a random point
  during focus and asks for a stretch of hands-off time, +10. Deliberately
  zero-interaction: it completes by *not* touching the phone. While tuning,
  it fires every block (`QuestBoard.surpriseChance`).
- **Move your body** (menu, automatic, once per day) — finish any workout
  today, +30. Completed by HealthKit, not by a tap: `WorkoutMonitor` observes
  workouts (read permission is asked the first time the quest appears) and
  the quest pays the moment one with today's end date syncs in — from the
  watch, the Fitness app, Strava, whatever. Background delivery (entitlement
  in `project.yml`) lets that happen while the app is suspended; without it
  the quest settles on the next foreground. It never fails — undone, it
  carries over, and the **break prompt suggests taking the break as a short
  walk** while it's open. Completion stamps the calendar day in
  `UserDefaults`, so it reappears each new day. To test in the Simulator:
  Health app → Browse → Activity → Workouts → Add Data.

## Signals (entitlement-free v1 fusion)

| Signal | How | Where |
|---|---|---|
| Left the app | `scenePhase` → `.background` while focusing | `ContentView` → `FocusEngine.sceneWentToBackground()` |
| Picked up the phone | CoreMotion device-motion heuristic (accel spike OR gravity/orientation change), debounced | `MotionDetector` |

No Family Controls / Screen Time entitlement is used, so nothing is gated on
Apple approval. DeviceActivity, app-shielding, and the dock are explicitly out
of scope here (CONCEPT.md §9 v2+).

## Run it

```bash
# Regenerate the Xcode project from project.yml after changing settings/sources:
cd ios && xcodegen generate

open ios/FocusSlice.xcodeproj
```

1. Select the **FocusSlice** scheme.
2. In **Signing & Capabilities**, pick your Team (a free Apple ID works for
   on-device runs; the bundle id is `com.ajschleg.FocusSlice` — change if needed).
3. Pick your iPhone as the run destination and ⌘R.

> Run on a **real device** to test pickups — CoreMotion reports nothing on the
> Simulator. Leave-the-app detection works in the Simulator too.

## How to test each signal

- **Left the app:** during a block, swipe to the Home Screen / app switcher → the
  "left app" counter increments, and it's logged in Review.
- **Pickup:** set the phone flat on a desk, start a block, give it a second or
  two (detection arms once the phone has been still for `stillDuration`), then
  lift it → the "pickups" counter increments.
- **Setting it down (should *not* count):** tap Start while holding the phone and
  take your time putting it down → no pickup. Detection models a pickup as the
  rest→motion transition, so it can only fire after the phone has actually been
  resting — the set-down motion happens while disarmed.
- **Lock & return (should log *nothing*):** during a block, press the side
  button to lock the phone, then unlock back into the app. Locking is phone
  discipline, not a distraction: the engine sees the device-lock signal
  (protected data becoming unavailable) and skips the "left app" record. No
  pickup either — motion sampling stops while the app is suspended, so on
  return the detector disarms and waits for the phone to rest again. (Without
  an immediate passcode requirement the lock signal can't fire, and a lock
  degrades to counting as "left the app".)

- **Locked-phone notification:** start a Quick test block, lock the phone, and
  wait out the minute — the "Focus block complete" notification lands on the
  lock screen. Unlock back into the app and the break prompt is waiting (the
  engine reads the wall clock on resume, so the block finishes correctly even
  though the timer didn't tick while suspended). Caveat: if you're wearing an
  unlocked Apple Watch, iOS routes the banner to the watch and the phone's
  lock screen stays empty — check your wrist or take the watch off to test.

Use the **Quick test** template (1 min) to iterate without waiting out a real block.

## Tuning the pickup heuristic

There is no "user picked up the phone" API, so `MotionDetector` fuses signals and
debounces. The knobs to tune on-device are at the top of `MotionDetector.swift`:

- `accelerationThreshold` — lower = more sensitive to movement
- `gravityDeltaThreshold` — lower = more sensitive to re-orientation
- `cooldown` — min seconds between counted pickups
- `stillAccelMax` / `stillGravityDeltaMax` / `stillDuration` — how still the phone must be, and for how long, before pickup detection arms. A pickup is the rest→motion transition, so nothing fires until the phone has genuinely been at rest — that's what keeps tapping Start in-hand, setting the phone down, and post-pickup fidgeting from counting
- `maxSampleGap` — a sampling gap longer than this means the app was suspended (locked/backgrounded); the detector disarms and waits for the phone to rest again, so the resume isn't read as a pickup

The goal of this slice is to answer: *does the resulting distraction log read as
true and motivating, or wrong and annoying?* That verdict decides whether the
whole concept has legs.
