# Focus App — The Class System (Draft for Review)

> Status: **draft for review — nothing here is implemented.** All player-facing
> names (classes, axes, prompt copy) are placeholders awaiting sign-off; the
> mechanics are tuned by feel and every number is a knob. Companion to
> CONCEPT.md — this layers onto the reward system (§5) and break design (§6).

## 1. What it is (one line)

A passive RPG class — **Warrior, Scholar, Artisan…** — computed from what the
player actually does (focus blocks, quests, break activities), appended to
their ladder level to form a title: **"Novice Warrior", "Disciple Monk",
"Enlightened Innkeeper."**

## 2. Design pillars

1. **The class mirrors the life; it doesn't demand one.** No grind targets, no
   class "damage". It's a portrait painted from behavior the player was doing
   anyway.
2. **Always on, never in the way.** The class computes in the background from
   day one. Every prompt that feeds it (onboarding quiz, break recap) is
   skippable, and skipping costs nothing. A player who ignores the system
   entirely still has a coherent title.
3. **Recent life > ancient history.** Affinity decays, so the class follows
   the player's *current* lifestyle and drifts naturally when it changes.
   That drift **is** the class-switching mechanic.
4. **Gentle nudges toward health, never shame.** If the body has been
   neglected for a while, the economy leans that way (a quest pays a little
   extra); nothing is lost, docked, or red.
5. **Dark-pattern guardrail (CONCEPT.md §5).** Self-reported activities pay
   **no coins** — they only feed the class. Where there's no reward, there's
   no incentive to lie, so the portrait stays honest and the recap stays
   guilt-free.

### Why breaks carry the class

Most of the class data comes from breaks and off-app life — three of the five
axes are fed almost entirely by break recaps, and Body mostly by HealthKit.
That's by design, not drift. During a focus block there's only one thing you
should be doing, so focus can't differentiate identity — it's already fully
measured by the score and the ladder. Variety lives in the breaks, so that's
where a portrait of *you* has to come from: **the ladder is what your focus
earns; the class is who you are between blocks.** This is also the deepest
implementation yet of CONCEPT.md's two break claims — breaks as first-class
(§6, the category differentiator) and rewarding proper breaks over grinding
(§5) — without adding a single coin to the break itself.

It stays a *focus* app because breaks are downstream of focus in the economy:
you can't take a break you didn't earn, and an early quit shrinks it, so the
recap moment — and all the class data flowing from it — only exists at the
rate you focus. Focus is the gate; breaks are the reward; the class is the
story the rewards tell.

Watch-item: the recap must never become break homework. No-coins and
skippability protect that today; if later class value (art, perks) makes
bubble-tapping feel worth optimizing, the fix is weighting verified signals
(HealthKit and whatever else syncs passively) above self-reports, so the
class keeps tracking life rather than diligent tapping.

## 3. The two tracks: ladder × class

The existing monk's ladder (CONCEPT.md §5D, `Levels.swift`) is untouched — it
stays the **performance** track (how well you focus). The class is the new
**identity** track (what your life looks like). They combine only in the
title:

```
[ladder level name] [class name]
Novice Warrior · Initiate Scholar · Pilgrim Wizard · Master Keeper
```

Naming constraint: ladder names are reserved words (Novice, Initiate,
Disciple, Pilgrim, Adept, Ascetic, **Sage**, Elder, Master, Enlightened) — no
class may reuse one, which is why there is no Sage class below.

## 4. The data: the Chronicle

A new local, append-only log — the **Chronicle** — records everything the
class is computed from (and future-proofs stats screens):

| Entry | Recorded when | Payload |
|---|---|---|
| Focus block | block reaches review | date, template, focused time, score, ended early |
| Quest completion | any quest completes | quest kind, date |
| Break recap | player taps bubbles after a break | activity kinds, date |
| Onboarding quiz | first launch | selected lifestyle chips |

Local only (a JSON file on device), like everything else in the app. No
account, no upload; HealthKit data never leaves the device.

## 5. Affinity: five axes

Every Chronicle entry drops **marks** on one of five axes:

| Axis (internal name) | The fantasy | Fed by |
|---|---|---|
| **Body** | strength, movement | exercise quest (2 marks — it's a verified workout), recap: exercised / walked / stretched |
| **Mind** | study, discipline | completed focus block (1), Clean sweep (1), Stillness check (1), recap: read / meditated |
| **Craft** | making things | recap: drew, wrote, played music, DIY |
| **Heart** | people | recap: talked with coworkers, called a friend, family time, played with a pet |
| **Hearth** | home & self-care | Hydrate quest (1), recap: watered plants, chores, cooked, coffee/tea ritual |

**Affinity = decay-weighted mark count.** Each mark's weight halves every 7
days (`0.5^(age/7d)`), so ~2 weeks of inactivity fades an axis to a whisper.
Soft cap of 4 marks per axis per day so one hyper-Saturday doesn't define the
class. (The recap's "scrolled my phone" honesty bubble feeds no axis — it
exists so skipping bubbles never feels like the only honest option.)

## 6. The class roster (all names DRAFT)

### Default

**Wanderer** — the classless class. No axis is awake yet (fresh install, quiz
skipped, or a quiet fortnight). Explicitly not a failure state: "Novice
Wanderer" is everyone's first title, and drifting back to Wanderer just means
the portrait has gone quiet. *(Name alternatives: Drifter, Villager,
Traveler.)*

### Base classes — one axis dominates

| Class | Axis | Requirement (draft) |
|---|---|---|
| **Warrior** | Body | Body affinity ≥ 4 and ≥ 1.6× the runner-up |
| **Scholar** | Mind | same shape, Mind on top |
| **Artisan** | Craft | same shape, Craft on top |
| **Bard** | Heart | same shape, Heart on top |
| **Keeper** | Hearth | same shape, Hearth on top *(alts: Steward, Druid)* |

"Affinity ≥ 4" ≈ four marks this week, or a steadier trickle across two.
The 1.6× dominance gap is what separates a base class from a hybrid.

### Hybrid classes — two axes within 0.6× of each other, both awake

Requires ladder level ≥ 3 (Disciple) — below that the dominant base class
shows. This is the "traverse by level" hook: early game stays simple, hybrids
read as an earned deepening.

| | **Mind** | **Craft** | **Heart** | **Hearth** |
|---|---|---|---|---|
| **Body** | Monk | **Wizard** | Paladin | Ranger |
| **Mind** | — | Artificer | Mentor *(alt: Oracle)* | Alchemist |
| **Craft** | — | — | Jester *(alts: Storyteller, Minstrel)* | Tinker |
| **Heart** | — | — | — | Innkeeper *(alt: Host)* |

Wizard is the canonical example: lift weights, draw on your breaks → "you
become a wizard." Alchemist falls out charmingly (deep focus + tea ritual);
Innkeeper too (chats + chores). Sample titles: *Disciple Monk, Adept
Alchemist, Ascetic Wizard, Elder Innkeeper.*

### Assignment rules, in order

1. No axis awake (all < 4) → **Wanderer**.
2. Top two axes both awake, runner-up ≥ 0.6× top, ladder level ≥ 3 → the
   **hybrid** for that pair.
3. Otherwise → the **base class** of the top axis.
4. **Hysteresis:** a newly computed title must repeat across 3 consecutive
   days before it's adopted, so a single odd weekend can't flap the class.
   Exception: leaving Wanderer is instant — the first class should land the
   moment it's earned.

### Switching classes

No menu, no button: **decay is the switch.** Two weeks of a new pattern
rewrites the portrait. (Open question §10: a later "Pursue a class" pin where
the player picks a target and the quest board leans offers toward its axes —
deliberately not in v1 until drift proves too slow or too fast.)

## 7. Feeding the Chronicle

### Onboarding quiz (first launch, one screen, skippable)

"What do you do in your free time?" — pick up to 3 chips:

> exercise & sports · walks outside · draw / write / make music · DIY & crafts
> · reading & learning · games & puzzles · gardening & plants · cooking &
> baking · time with friends & family

Each chip seeds ~3 marks on its axis — a two-week head start that **decays
like any other mark**, so the quiz biases the opening portrait and then real
behavior takes over. Skip → zero marks → Wanderer. Asked once, never again.

### Break recap (after each taken break, skippable)

When a break ends (only a real one — skipped breaks get no recap), the review
screen opens with one row of bubbles: *"What did you get up to?"*

> exercised · walked · stretched · art · read · meditated · watered plants ·
> chores · cooked · coffee/tea · talked with someone · scrolled my phone

Tap up to 3, or ignore it — it's a section of the review screen, not a modal
gate. No coins (pillar 5); each tap is one mark. The bubble list is one
data table, easy to extend.

### Existing automatic signals (no new interaction)

Focus blocks → Mind. The exercise quest → Body (HealthKit-verified, hence the
double mark). Hydrate → Hearth. Clean sweep / Stillness → Mind. The class has
a pulse even for a player who skips every prompt — pillar 2.

## 8. Nudges (the "slightly healthier" lean)

Checked weekly, at most **one nudge active at a time**, never stacking:

- **Body asleep 7+ days** → the exercise quest advertises a temporary bonus
  ("Move your body pays double this week") and the break prompt's walk nudge
  copy leans harder.
- **Hearth asleep 7+ days** → Hydrate gets the same treatment.
- Ignored three weeks running → that nudge goes quiet for a month. The lean
  is always a *bonus*, never a penalty — nothing is lost by ignoring it
  (pillar 4, CONCEPT.md §5's dark-pattern line).

Mind needs no nudge; the core loop is the Mind nudge.

## 9. Where the player sees it

- **Plan screen badge:** "Level 3 · Disciple **Warrior**" — the class simply
  joins the line that exists today.
- **Class change:** a small dismissible card on the plan screen — "Your path
  has shifted: Scholar → Monk." No modal, no fanfare (pillar 2).
- **v1 stops there.** No class artwork, no perks, no stats screen. Cosmetic
  title first; if it feels alive, later versions can add class art, a
  Chronicle screen (the affinity portrait), and class-flavored quest skins.

## 10. Open questions (for Austin)

1. **Names.** Whole roster is draft — especially Keeper, Mentor, Jester,
   Innkeeper, and the default Wanderer. And is a **Monk** class too redundant
   with the monk-themed ladder, or a perfect fit?
2. **Quiz timing.** First launch is one more screen before the first block —
   acceptable, or defer to after the first review?
3. **Recap placement.** Top of the review screen (proposed) vs. its own
   moment between break and review?
4. **Hybrid gate.** Ladder ≥ 3 to show hybrids — right bar? Alternative: gate
   on total marks instead of level.
5. **Pursue-a-class pin** (explicit switching) — v2 as proposed, or v1?
6. **Should the exercise quest's double mark extend to other verified
   signals later** (e.g., mindful minutes from HealthKit → Mind)?

## 11. Implementation sketch (when approved)

Mirrors the patterns already in the codebase — observers around the engine,
one data table per concept:

- `ChronicleStore` — append-only Codable JSON log; observes the engine and
  quest board the way `QuestBoard` observes the engine today.
- `ClassEngine` — pure function `(chronicle, date) → title`; roster, axis
  mappings, and every threshold in **one table** (`ClassDefinition.roster`),
  exactly like `FocusLevel.ladder`.
- `BreakRecapView` (review-screen section), `OnboardingQuizView` (one
  screen), and a one-line change to the plan badge.
- Nothing touches `FocusEngine` — the class layer can ship, change, or be
  deleted without entering block logic.
