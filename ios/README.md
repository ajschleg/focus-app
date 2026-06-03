# FocusSlice — v1 vertical slice

A deliberately thin, ugly-on-purpose prototype to validate the **one risky thing**
in CONCEPT.md: can we detect distraction well enough (within Apple's privacy
limits, §3) for the core loop to feel *honest*? Everything else — the reward
economy, breaks, hard enforcement — is intentionally left out.

What it does: **Plan** (pick a length) → **Focus** (countdown + live distraction
counts) → **Review** (focused time, distraction log, a toy score).

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
- **Pickup:** set the phone flat on a desk, start a block, wait ~2s, then lift it →
  the "pickups" counter increments.

Use the **Quick test** template (1 min) to iterate without waiting out a real block.

## Tuning the pickup heuristic

There is no "user picked up the phone" API, so `MotionDetector` fuses signals and
debounces. The knobs to tune on-device are at the top of `MotionDetector.swift`:

- `accelerationThreshold` — lower = more sensitive to movement
- `gravityDeltaThreshold` — lower = more sensitive to re-orientation
- `cooldown` — min seconds between counted pickups
- `settleDelay` — grace period after start so setting the phone down doesn't self-trigger

The goal of this slice is to answer: *does the resulting distraction log read as
true and motivating, or wrong and annoying?* That verdict decides whether the
whole concept has legs.
