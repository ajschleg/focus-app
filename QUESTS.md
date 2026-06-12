# FocusSlice — Quest catalog (single source of truth)

> Every quest in the game: what it is, when it appears, what it pays, and
> which affinity it feeds. The code lives in `ios/Sources/Quests.swift` and
> `QuestBoard.swift`; the affinity axes are defined in CLASSES.md §5. When a
> quest is added or retuned, update this doc — rewards and copy here mirror
> the code.

## The four patterns

- **Self-report** — honor system, completed by tapping Done. For healthy
  habits no sensor can verify. Never judged, cannot fail.
- **Auto-judged (opt-in)** — taken on deliberately with Accept, then judged
  against the block's signals. Can fail; unaccepted it sits dormant.
- **Surprise** — springs mid-block, zero interaction by design (a quest you
  had to tap would be the distraction it polices). Completes by *not*
  touching the phone.
- **Automatic (verified)** — completed by an outside signal (HealthKit).
  No buttons at all; never fails, just carries over.

## Current quests

| Quest | Pattern | When it appears | Reward | Affinity | Player copy |
|---|---|---|---|---|---|
| **Hydrate** | Self-report | Prompt sheet when tapping "Start focus"; a skipped offer re-prompts next block. Not shown on the quest board. | 5 | Hearth +1 | "Drink a glass of water before this block." |
| **Clean sweep** | Auto-judged, opt-in | Quest board row each cycle; judges the next block only if accepted first. Dies on the first distraction or an early quit. | 25 | Mind +1 | "Finish your next block with zero distractions." |
| **Stillness check** | Surprise | Springs 20–50% of the way into a focus block (every block while tuning — `QuestBoard.surpriseChance`). Window: up to 5 minutes, never more than half the time left, skipped entirely under 15 seconds. | 10 | Spirit +1 | "Hands off the phone for the next *X*." |
| **Move your body** | Automatic (HealthKit) | Quest board row on days it hasn't been earned yet; completes the moment any workout with today's end date syncs in. While open, the break prompt suggests taking the break as a short walk. | 30 | Body +2 | "Finish any workout today. Completes on its own when Health logs one." |

Affinity notes: marks land in the Chronicle when a quest completes — live
once the classes feature ships (CLASSES.md §4). Verified signals mark
double (hence Body +2); self-reports mark single, which keeps lying
low-stakes (CLASSES.md pillar 5 applies to recap bubbles, which pay no
coins at all — quests pay coins because three of the four are sensor- or
opt-in-judged).

## Lifecycle rules

- Statuses are one-way: offered → active → completed / failed.
- Coins pay the instant a quest completes (`QuestBoard`'s payout watcher),
  wherever the player is in the loop.
- Resolved quests show once on the review screen, then are swept when
  planning resumes; fresh offers are seeded each cycle.
- **Move your body** is once per calendar day (completion stamps the day);
  it never fails and carries over while unearned. All others are
  once per cycle.

## Tuning & nudges

- `surpriseChance` is pinned to 1.0 while the slice is tuned — drop it once
  surprise should mean surprise.
- Starving-axis nudges (CLASSES.md §8): Body asleep 7+ days → Move your
  body advertises double pay for the week; Hearth asleep → the same for
  Hydrate. At most one nudge active at a time; always a bonus, never a
  penalty.

## Pipeline

- **Class trials** (CLASSES.md §13, post-v1): board-offered themed quests
  when a rising second axis puts a new class in reach — "The Wizard stirs:
  two workouts and a sketch this week."
- Architecture makes additions cheap: a new quest is a `Quest` subclass plus
  a seed entry in `QuestBoard.seedMenuOffers` (see ios/README.md), and a row
  in this catalog.
