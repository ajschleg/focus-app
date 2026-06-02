# Focus App — Product Concept (Draft for Review)

**Working name:** TBD &nbsp;•&nbsp; **Platform:** iOS (native, Swift / SwiftUI) &nbsp;•&nbsp; **Status:** Concept draft &nbsp;•&nbsp; **Date:** 2026-06-02

> A thinking-partner summary of the idea so far. Nothing here is locked — it's meant to be marked up and argued with. Open decisions are collected in §11.

---

## 1. What it is (one line)

A **structured-day coach** that splits your day into focus blocks and real breaks, treats *unearned* phone use as the thing to minimize, and turns *earned* phone time plus visible progress into the reward.

**The core reframe:** the phone isn't the enemy — using it *off-plan* is. Earned break-time becomes the currency you work toward. This is the whole pitch, because it dissolves the "nagging punishment app" feeling that kills most focus tools.

---

## 2. Core loop

1. **Plan** — lay the day out as blocks: focus segments + breaks. Can be rigid (templates like 50/10, 90/20, or pulled from your calendar) or loose ("hit 3 deep-work blocks today").
2. **Focus** — timer runs, phone is monitored, distractions logged, optional ambient audio.
3. **Break** — a *structured* track (stretch / walk / hydrate / breathe / look away from screen) **or** a *free* track where you spend the currency you just earned (guilt-free phone time).
4. **Review** — end-of-block and end-of-day scoring → rewards, streak, progress on whatever you're building.

---

## 3. The iOS reality (this shapes everything)

The single most important design constraint. Your first instinct — log *exactly when* you pick up the phone, minute by minute — runs into Apple's privacy wall. Design *with* it, not against it.

### What you CAN detect

| Signal | API | Notes |
|---|---|---|
| You left your own app during a focus block | `scenePhase` / app lifecycle | Strong "I got distracted" signal, **no special entitlement**. This is how Forest works. |
| Phone was picked up / moved | **CoreMotion** (accelerometer, gyro, magnetometer, device motion) | Real-time while your app is foregrounded. Coarse historical motion (`CMMotionActivity`: stationary/walking/etc.) is queryable even after the app was suspended. |
| A distracting app/category crossed a usage threshold during a focus window | **DeviceActivity** (schedules + thresholds → callbacks into a sandboxed extension) | You pick the apps via a system picker; you get *threshold events*, not a timeline. |
| Screen-on / unlock | system signals | Best combined with the above. |
| Block a distracting app outright | **ManagedSettings** (shield apps) | For "hard" enforcement mode. |

### What you CANNOT do

- **No granular event stream** like *"opened TikTok at 3:42 for 7 min."* Apple makes this impossible for third-party apps by design.
- **Apps are opaque tokens** — you can't even read which app a token refers to; the system resolves it. You store tokens, not names.
- **No unlimited background polling** — a regular app is suspended when backgrounded, so high-rate real-time sensing while the phone sleeps on the desk is restricted.

### The takeaway: sensor fusion, not one magic signal

The realistic, *richer-than-any-gyro* distraction signal is a **fusion** of: left-my-app + CoreMotion pickup + screen-on/unlock + DeviceActivity threshold trips. Your distraction log honestly reads like *"Focus block 2 — left the app 3×, social-app limit tripped once,"* not a second-by-second feed. That's both achievable and enough.

> **Entitlement note:** the Family Controls / Screen Time APIs need a **distribution entitlement requested from Apple** (fine for personal/dev use; an extra approval step for App Store). The lifecycle + CoreMotion approach needs none — see the MVP split in §9.

---

## 4. Distraction detection: strictness is a dial, not a rule

"What counts as a distraction" is personal, so make it a setting:

| Mode | Behavior |
|---|---|
| **Soft** | Just log it + gentle nudge. No blocking. |
| **Medium** | Friction: a breath / "you're in a focus block — sure?" interstitial before a distracting app opens (the *one sec* mechanic). |
| **Hard** | Actually shield distracting apps until the break (`ManagedSettings`). |

**Grace mechanics (essential — don't punish legit use):**
- Allow-list: work apps and your own tools don't count.
- Emergency / "I need my phone" escape hatch.
- Phone-call exemption. (Nothing kills a focus app faster than being punished for answering a call.)

---

## 5. Reward system (your real edge)

This is a crowded category (Forest, Opal, one sec, Brick…), and the reward design is where you'd win — **especially as a game dev.** Four building blocks:

- **A — Earned currency ("focus coins").** Earn per focused minute; bonus for a clean block; multiplier for streaks. The clever part: **you spend coins on guilt-free phone time and break activities.** Phone use stops being pure sin and becomes the thing you earned. Self-balancing economy.
- **B — Build-a-world (the signature hook).** Every clean focus block feeds a persistent little world — a ship, a port, an island — that grows over weeks. Distractions stall or wilt it. This is squarely in your wheelhouse, it's the most defensible differentiator in the category, and it's weeks-long visible proof of accumulated focus. (Forest does this shallowly with one tree; you could do it as a real idle/management game fed by actual focus.)
- **C — Light stakes (loss aversion).** Forest's "leave and your tree dies." Powerful, but use *sparingly* — too much and it feels like a punisher you'll delete. (Skip money-staking à la Beeminder for now: payments + regulation = a different project.)
- **D — Streaks & levels.** Cheap, strong habit glue layered on top of the others.

**Suggested mix:** **B** as the hook, **A** as the economy underneath it, **D** for daily glue, a *gentle* touch of **C**.

**Two things the reward system must get right:**
1. **Reward proper breaks, not just grinding.** Penalize *skipping* breaks and overwork too — the goal is sustainable focus, not a manic streak that burns you out. Don't let people bank infinite focus.
2. **Watch the dark-pattern line.** Variable rewards are potent but can spawn a *new* compulsion. The meta-game should serve the work and be easy to ignore on days you just want to head down and work.

---

## 6. Break design

Make breaks first-class, not just "focus paused":
- **Structured track:** stretch, walk, hydrate, breathe, look away from the screen — restorative and *off-screen*.
- **Free track:** spend coins on earned phone time.

Actively nudging people *off* the screen during breaks (instead of letting "break" become doomscrolling) is itself a differentiator — most focus apps ignore the break entirely.

---

## 7. Hardware (optional, later) — the dock

The back-of-phone gyro **puck is dropped** — the phone already has a better IMU, and motion is a weak proxy for distraction (false positives from notifications/bumps; false negatives from reading a flat phone).

If hardware ever comes back, the right form is a **dock the phone rests in during focus**, and its value is *behavioral*, not sensing:
- **Undocking = the distraction event** — a clean binary signal, none of the gyro false-positive mess.
- **A commitment ritual** — physically docking the phone is a behavioral cue that works *because* it's friction (cf. **Brick**, whose value is the tap ritual while the blocking is done in software).
- **Ambient off-phone display** — e-ink / LED ring showing timer, coins, streak, world progress. Glanceable feedback that isn't on the screen you're avoiding.
- **Charging is a feature** — the dock charges the phone during focus.

Caveat: even the dock's core undock signal is partly detectable in software (charging-state change), so a dock has to justify itself on **ritual + delight + tamper-resistance**, not data. **Verdict: software-first; revisit the dock only once the app proves the loop works.**

---

## 8. Where this sits vs. existing apps

- **Forest** — loss-aversion + grow-a-tree; foreground/background only.
- **Opal** — heavy Screen Time blocking + stats.
- **one sec** — friction-before-opening.
- **Pomodoro apps** (Be Focused, Focus To-Do) — timing only, no phone awareness.

**Nobody cleanly combines** structured day-planning + Screen Time-aware distraction logging + a deep, game-like reward economy. That intersection — plus your ability to actually build a satisfying progression loop — is the opening.

---

## 9. Scope: MVP vs. later

| | **v1 (MVP — no special entitlement)** | **v2+** |
|---|---|---|
| Day planning | Templates + simple block timer | Calendar import, smart suggestions |
| Distraction sensing | Leave-the-app detection + CoreMotion pickup | + DeviceActivity thresholds, per-app/category, screen-on |
| Enforcement | Soft (log + nudge) | Medium (friction) & Hard (shield apps) |
| Rewards | Coins + streaks (A + D) | Build-a-world (B), light stakes (C) |
| Breaks | Structured + free tracks | Richer activity library |
| Hardware | None | Dock (only if it earns its place) |

Shipping v1 without the Family Controls entitlement lets you validate the loop fast; the Screen Time depth is an additive layer.

---

## 10. Practical prerequisites

- **Xcode + Swift/SwiftUI** (native is required for these APIs — not a good fit for a Godot export).
- **Apple Developer Program** (~$99/yr) for on-device testing and entitlements.
- A **physical device** — Screen Time / DeviceActivity don't fully work in the simulator.
- **Family Controls distribution entitlement** request to Apple (only when you add the Screen Time layer in v2).

---

## 11. Open decisions

1. **Enforcement philosophy** — gentle coach (log + nudge) or hard enforcer (block apps)? Decides whether v1 needs the Family Controls entitlement at all.
2. **Reward flavor** — commit to the build-a-world game, or a cleaner points/streaks system? (Given your background, the world is the bet.)
3. **Scope of "the plan"** — rigid scheduled blocks, or loose daily goals?
4. **Name.**

---

*Next options: turn this into an MVP feature spec, sketch the core screens/flows, or detail the v1 sensor-fusion stack (what each API hands you and how they combine).*
