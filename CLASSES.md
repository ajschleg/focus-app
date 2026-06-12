# Focus App — The Class System (Draft for Review)

> Status: **draft for review — nothing here is implemented.** All player-facing
> names (classes, axes, prompt copy) are placeholders awaiting sign-off; the
> mechanics are tuned by feel and every number is a knob. Companion to
> CONCEPT.md — this layers onto the reward system (§5) and break design (§6).

## 1. What it is (one line)

A passive RPG class — **Warrior, Scholar, Artisan…** — computed from what the
player actually does (focus blocks, quests, break activities), appended to
their ladder level to form a title: **"Novice Warrior", "Journeyman Monk",
"Paragon Innkeeper."**

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
6. **Built to grow.** The roster will deepen as the app does — new
   activities, axes, classes, epithets. So extensibility is a hard
   requirement of the implementation, not a nice-to-have: adding a class or
   even a whole axis must be a data-table edit (a new row, a new activity
   mapping), never a logic change. The 29 titles below are a starting cast,
   not the cap.

### Why breaks carry the class

Most of the class data comes from breaks and off-app life — five of the seven
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

The guild ladder (CONCEPT.md §5D, `Levels.swift`) keeps its mechanics — it
stays the **performance** track (how well you focus). The class is the new
**identity** track (what your life looks like). They combine only in the
title:

```
[ladder level name] [class name]
Novice Warrior · Apprentice Scholar · Journeyman Wizard · Paragon Keeper
```

The ladder uses **guild ranks** (decided): Novice, Apprentice, Journeyman,
Adept, Veteran, Expert, Master, Grandmaster, Luminary, Paragon. These are
reserved words no class may reuse — the rename away from the old monk theme
freed "Sage" for the roster and un-clashed the Monk class.

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
account, no upload; HealthKit data never leaves the device. Append-only and
**never pruned**: an entry is a kind and a date, so a decade costs
kilobytes — and the year recap (§13) needs the full history.

## 5. Affinity: seven axes

Every Chronicle entry drops **marks** on one of seven axes:

| Axis (internal name) | The fantasy | Fed by |
|---|---|---|
| **Body** | strength, movement | exercise quest (2 marks — verified workout), recap: exercised / stretched / walked / danced |
| **Mind** | study, learning | completed focus block (1), Clean sweep (1), recap: read / practiced a language / puzzles & chess / listened to something that teaches |
| **Spirit** | stillness, the inner life | Stillness check (1), recap: meditated / breathwork / journaled / yoga / sat and did nothing |
| **Craft** | making things | recap: drew or painted / wrote / played music / photography / DIY & handiwork |
| **Heart** | people | recap: talked with coworkers / called a friend or family / played with a pet / helped someone / volunteered |
| **Hearth** | home & self-care | Hydrate quest (1), recap: chores & tidying / cooked or baked / coffee-tea ritual / ran an errand |
| **Wild** | green & growing things | recap: watered the plants / gardened / sat outside / hiked / watched the birds |

Splitting five axes into seven (Spirit out of Mind, Wild out of Hearth) is
what buys the bigger roster below: meditation no longer hides inside "study",
and gardening no longer counts as a chore. (Quest mechanics — triggers,
rewards, player copy — live in QUESTS.md, the quest source of truth.)

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
| **Mystic** | Spirit | same shape, Spirit on top *(alts: Oracle, Dreamer)* |
| **Artisan** | Craft | same shape, Craft on top |
| **Bard** | Heart | same shape, Heart on top |
| **Keeper** | Hearth | same shape, Hearth on top *(alt: Steward)* |
| **Druid** | Wild | same shape, Wild on top |

"Affinity ≥ 4" ≈ four marks this week, or a steadier trickle across two.
With seven axes spreading marks thinner, the awake bar may need to drop to 3
— tune by feel. The 1.6× dominance gap is what separates a base class from a
hybrid.

### Hybrid classes — two axes within 0.6× of each other, both awake

Requires ladder level ≥ 3 (Journeyman) — below that the dominant base class
shows. This is the "traverse by level" hook: early game stays simple, hybrids
read as an earned deepening.

| | **Mind** | **Spirit** | **Craft** | **Heart** | **Hearth** | **Wild** |
|---|---|---|---|---|---|---|
| **Body** | Monk | Templar | **Wizard** | Paladin | Blacksmith | Ranger |
| **Mind** | — | Philosopher | Artificer | Sage | Alchemist | Naturalist |
| **Spirit** | — | — | Calligrapher | Cleric | Candlekeeper | Shaman |
| **Craft** | — | — | — | Jester | Tinker | Herbalist |
| **Heart** | — | — | — | — | Innkeeper | Shepherd |
| **Hearth** | — | — | — | — | — | Homesteader |

*(Alternatives for contested cells: Templar → Warden · Sage → Mentor, Oracle
· Cleric → Healer · Candlekeeper → Abbot, Lamplighter · Shaman → Hermit ·
Jester → Storyteller, Minstrel · Blacksmith → Squire · Innkeeper → Host.)*

Wizard is the canonical example: lift weights, draw on your breaks → "you
become a wizard." New favorites fall out naturally: **Alchemist** (deep focus
+ tea ritual), **Calligrapher** (art + stillness), **Homesteader** (cooking +
garden), **Shepherd** (people + outdoors), **Naturalist** (study + green
things), **Candlekeeper** (home ritual + quiet). Sample titles: *Journeyman
Monk, Veteran Alchemist, Adept Naturalist, Expert Calligrapher, Grandmaster
Homesteader, Paragon Shaman.*

All told: 7 base + 21 hybrids + Wanderer = **29 titles**.

### The "why this title" lines (all DRAFT)

Every class carries a one-sentence, second-person answer to "why am I
this?", shown from the small ⓘ next to the title (§9). It's one more column
in the roster table — a new class isn't done until its why-line exists
(pillar 6). Base classes share a deliberate refrain ("…claims your weeks")
so they read as a family; hybrids get their own cadence.

| Class | Why-you line |
|---|---|
| Wanderer | Every path is still open — no single pursuit has claimed your weeks yet. |
| Warrior | Movement claims your weeks: workouts, stretches, active breaks. |
| Scholar | Study claims your weeks: reading, languages, learning. |
| Ascetic | Focus itself claims your weeks: block after block of undivided attention. |
| Mystic | Stillness claims your weeks: meditation, journaling, quiet. |
| Artisan | Making claims your weeks: drawing, writing, music, craft. |
| Bard | People claim your weeks: conversation, calls, company. |
| Keeper | The home claims your weeks: cooking, tidying, small rituals. |
| Druid | Green things claim your weeks: plants, gardens, open air. |
| Monk | Training and study in balance — strong back, sharp mind. |
| Templar | Sweat beside stillness — you train the body and quiet the mind. |
| Wizard | Iron and ink — you train hard and you make things. |
| Paladin | Strength spent on people — you move, and you show up. |
| Blacksmith | Muscle at the hearth — workouts beside house-work. |
| Ranger | Your training lives outdoors — movement among green things. |
| Philosopher | You learn, then sit with it — study beside reflection. |
| Artificer | You learn things, then build them. |
| Sage | Learning shared — study beside good company. |
| Alchemist | Deep focus, home ritual — study brewed with tea. |
| Naturalist | You study the world, then go walk in it. |
| Calligrapher | Quiet hands, made things — craft beside stillness. |
| Cleric | Calm given away — stillness beside care for people. |
| Candlekeeper | Small flames kept lit — quiet ritual at home. |
| Shaman | Your stillness happens outside — quiet among green things. |
| Jester | Made to be shared — your craft happens in company. |
| Tinker | You fix and make around the house. |
| Herbalist | Craft from what grows — making beside the garden. |
| Innkeeper | A home with people in it — hosting, cooking, company. |
| Shepherd | Company taken outdoors — people and pastures. |
| Homesteader | You grow it, then you cook it — garden beside kitchen. |

### Class art (single source of truth: ART.md)

The art direction — Oblivion-manual figures, modernized — plus all 30
per-class figure briefs and the image-model prompt template live in
**ART.md**. The roster rule stays here (pillar 6): a class isn't done
without its why-line and its ART.md brief. Not v1 scope (§9).

### Epithets (one ships in v1, the rest later)

When a single activity supplies most of the top axis (say ≥ 60% of its
marks), the base name sharpens into an epithet: a Scholar who mostly
practices languages becomes a **Linguist**, a Keeper who mostly cooks a
**Chef**, an Artisan who mostly writes a **Wordsmith**, a Bard who's all pet
time a **Beastfriend**. Pure renames over the same data — variety scales
with the activity vocabulary instead of new mechanics. Ground rules:
epithets rename **base classes only** (hybrids and Wanderer never take
them), and an epithet flip obeys the same 3-day hysteresis as any drift —
no flapping at the 60% line.

One epithet ships in v1 because it covers the app's most common player:
**Mind dominated by focus blocks → Ascetic** *(alts: Sentinel, Archer,
Delver)* — the one who denies every distraction. A freed ladder word: the
old monk ladder retired it, and it fits the focuser better as an identity
than it ever did as a rank. "Scholar" should mean books and languages, not
block counts; the pure focuser deserves their own name (decided — §10 #10). The rest of the epithet table stays v2: the
roster should prove itself first.

### Assignment rules, in order

1. No axis awake (all < 4) → **Wanderer**.
2. Top two axes both awake, runner-up ≥ 0.6× top, ladder level ≥ 3 → the
   **hybrid** for that pair.
3. Otherwise → the **base class** of the top axis.
4. **Hysteresis on an active-days clock:** a newly computed title must
   repeat across 3 consecutive **active days** — days with at least one
   Chronicle entry — before it's adopted, so a single odd weekend can't
   flap the class. Silence never advances the clock: a trip or a sick week
   of any length holds the title until fresh evidence says otherwise. *The
   class changes on evidence of a changed life, never on absence.*
   Exception: leaving Wanderer is instant — the first class should land the
   moment it's earned. The same held clock guards the slide *back* to
   Wanderer when every axis fades.
5. **Gate changes are instant; drift changes are held.** Hysteresis governs
   affinity-driven changes only. Crossing the hybrid gate (promotion to
   Journeyman) re-renders the title immediately, and a demotion below it
   collapses a hybrid to the dominant base class until the gate is
   re-earned — the affinities underneath are untouched either way.
6. **Ties keep the incumbent.** Exactly-equal affinities never flap the
   class: the current class wins ties; with no incumbent, higher lifetime
   marks break it, then §5 table order. Same chronicle, same title, always —
   that determinism is what makes the engine testable (§12).

### The silent player (no quiz, no recaps — a worked example)

Skipping every prompt forever is a supported way to play (pillar 2), so the
automatic signals decide the story. Focus blocks feed Mind, which makes the
pure focuser's path: **Novice Wanderer → Ascetic within about a week of
daily blocks** (the focus-dominated epithet of Scholar), then up the ladder
— the level climbs, the class holds, and *Grandmaster Ascetic* is a
perfectly good silent endgame. Start reading or practicing a language on
breaks and the epithet dissolves into Scholar proper. The ladder never
chooses the class; the hybrid gate is the only place level and class touch.

Quests are the silent player's only other voice: add the exercise quest most
days and Body wakes — **Monk** from Journeyman up (or Warrior if training
dominates). Hydrate every block and **Alchemist** comes into reach. All
deliberate: for a player who gives the app nothing else, "you focus and you
train" *is* the portrait. The §12 tests pin these paths so tuning can't
quietly reroute them.

### Switching classes

No menu, no button: **decay is the switch.** Two weeks of a new pattern
rewrites the portrait. (Open question §10: a later "Pursue a class" pin where
the player picks a target and the quest board leans offers toward its axes —
deliberately not in v1 until drift proves too slow or too fast.)

This is also the late-bloomer story: a Grandmaster Ascetic who finally
starts tapping recap bubbles (or logging workouts) shifts class like anyone
else — the decay crossover plus the three-day hold, level untouched. The
gate is long behind them, so hybrids unlock the moment a second axis wakes.

## 7. Feeding the Chronicle

### The lifestyle quiz (after the first review, one screen, skippable)

Deliberately **not** on first launch — install-time questionnaires are
exactly the thing people bounce off (and there's no account here to hang one
on). It appears once, right after the player's **first review screen**:
they've just watched a block turn into a score, so "the app turns how you
live into a class" finally has context.

"What do you do in your free time?" — pick up to 3 chips:

> exercise & sports · walks & runs · reading & learning · languages &
> puzzles · meditation & mindfulness · journaling & quiet time · art, music
> & writing · DIY & crafts · friends & family · time with pets · cooking &
> baking · tidying & home projects · gardening & plants · hiking & nature

(Two chips per axis, fourteen total — one screen.)

**The pitch matters more than the screen.** It has to say why the quiz is
worth ten seconds *and* that skipping is genuinely fine — both at once.
Draft copy (for sign-off):

> **Give your story a head start.**
> FocusSlice quietly turns how you live — focus, breaks, free time — into an
> RPG class. Pick what already fills your free time and your class gets a
> two-week head start. Skip it and nothing is lost: your habits will paint
> the same portrait, just a little slower. (Stays on your phone, like
> everything else.)
>
> *Done* · *Skip — my habits can speak for themselves*

Each chip seeds ~3 marks on its axis — a head start that **decays like any
other mark**, so the quiz biases the opening portrait and then real behavior
takes over. That decay is also why the "skipping is fine" line is honest,
not soft-pedaling: takers and skippers converge on the same class within a
couple of weeks; skippers just wear Wanderer a little longer. Asked once,
never again — and deliberately no late retake: a quiz taken at Grandmaster
would be a no-op, three decaying seed marks against months of Chronicle.
It's a cold-start tool, nothing more (§12 pins that with a test).

Build note: the quiz only matters at install time, so it's **ship-blocking,
not prototype-blocking** — it's the last piece of this feature to build,
after the engine and recap have proven themselves on real Chronicle data.

### Break recap (after each taken break, skippable)

When a break ends (only a real one — skipped breaks get no recap), the recap
gets **its own moment between break and review** (decided — §10 #3): one
light screen asking *"What did you get up to?"*, in the same spirit as the
pre-focus Hydrate sheet. Continue lands on the review; Skip is just as easy
and lands in the same place.

The full bubble vocabulary is the recap column of the axis table (§5), plus
the no-axis honesty bubble *scrolled my phone*. Showing twenty-odd bubbles
every time would be homework, so the recap shows **nine**: the player's six
most-tapped, two drawn from the sleepiest axes (the nudge surface working
quietly — §8), and *scrolled my phone* — with a "more…" chip expanding the
rest.

Because this moment stands between the player and their score, it must stay
feather-light forever: bubbles, Continue, Skip — it never grows questions,
text fields, or a second step. Tap up to 3 or skip; no coins (pillar 5);
each tap is one mark. The bubble list is one data table, easy to extend.

### Existing automatic signals (no new interaction)

Focus blocks → Mind. The exercise quest → Body (HealthKit-verified, hence the
double mark). Hydrate → Hearth. Clean sweep → Mind; Stillness check → Spirit
(it is literally stillness). The class has a pulse even for a player who
skips every prompt — pillar 2.

## 8. Nudges (the "slightly healthier" lean)

Checked weekly, at most **one nudge active at a time**, never stacking:

- **Body asleep 7+ days** → the exercise quest advertises a temporary bonus
  ("Move your body pays double this week") and the break prompt's walk nudge
  copy leans harder.
- **Hearth asleep 7+ days** → Hydrate gets the same treatment.
- Ignored three weeks running → that nudge goes quiet for a month. The lean
  is always a *bonus*, never a penalty — nothing is lost by ignoring it
  (pillar 4, CONCEPT.md §5's dark-pattern line).
- Quietest of all: the recap's two sleepy-axis bubble slots (§7). No banner,
  no bonus — the option is simply *there*, suggesting itself.

Mind needs no nudge; the core loop is the Mind nudge.

## 9. Where the player sees it

- **Plan screen badge:** "Level 3 · Journeyman **Warrior**" — the class
  simply joins the line that exists today.
- **The ⓘ beside the title:** a small info button on the badge opens a
  popover answering *why this title*. Two layers: the class's why-line from
  the roster table, then a receipts line generated from the Chronicle —
  "driven by 5 workouts · 4 sketches · 3 walks these past two weeks" — so
  the answer is personal evidence, not canned copy. After a long quiet
  stretch the receipts say so plainly — "your Chronicle has been quiet
  lately" — so a title held through absence (rule 4) is transparent, never
  a lie. (What the popover says about the *level* half of the title is
  still open — §10.)
- **Class change:** a small dismissible card on the plan screen — "Your path
  has shifted: Scholar → Monk." No modal, no fanfare (pillar 2). One
  exception: the **first** class award — the day Wanderer ends — gets a
  single full-screen ceremony: the art, the why-line, "You've been seen."
  Every later shift is the quiet card.
- **v1 stops there.** No class artwork, no perks, no stats screen. Cosmetic
  title first; if it feels alive, the depth roadmap (§13) takes over —
  character sheet, codex, trials, class voice, widgets, the year recap.

## 10. Open questions (for Austin)

1. **Names.** Whole roster is draft — especially Keeper, Sage, Jester,
   Innkeeper, and the default Wanderer. (Resolved: the ladder is guild ranks,
   Novice → Paragon, so a Monk class no longer clashes with a monk-themed
   ladder — and the freed "Sage" now sits in the Mind+Heart cell.)
2. **Quiz timing.** Resolved: after the first review, never at install, with
   the head-start-but-skippable pitch (§7); built last, at the ship pass.
3. **Recap placement.** Resolved: its own moment between break and review —
   a dedicated, feather-light screen (bubbles · Continue · Skip), per §7.
4. **Hybrid gate.** Ladder ≥ 3 to show hybrids — right bar? Alternative: gate
   on total marks instead of level.
5. **Pursue-a-class pin** — resolved: ships post-v1 as class trials (§13),
   offered by the quest board when a rising second axis makes a new class
   reachable.
6. **Should the exercise quest's double mark extend to other verified
   signals later** (e.g., mindful minutes from HealthKit → Spirit)?
7. **Seven axes — the right grain?** Five felt cramped once meditation,
   languages, gardening, and pets arrived; nine would be a horoscope. The
   borderline call: pets under Heart (companionship) or Wild (animals)?
8. **Name flavor comfort.** Templar, Cleric, Shaman, Monk lean on real
   traditions — fine for the audience, or swap for the secular alternatives
   listed under the matrix?
9. **Recap subset size.** Nine visible bubbles (six habitual + two sleepy +
   honesty) — right amount, or fewer?
10. **Epithets** — resolved: one ships in v1 (focus-dominated Mind →
    Ascetic, so "Scholar" stays a study word); the rest of the table is v2.
11. **The level half of the ⓘ popover.** The class half is settled (why-line
    + receipts); what should it say about the ladder rank? Likely shape: the
    rank's plain meaning plus live progress ("Journeyman — rank 3 of 10.
    Score 60+ in a block to climb"), which the badge's progress line already
    knows how to compute. Undecided.

## 11. Implementation sketch (when approved)

Mirrors the patterns already in the codebase — observers around the engine,
one data table per concept:

- `ChronicleStore` — append-only Codable JSON log; observes the engine and
  quest board the way `QuestBoard` observes the engine today.
- `ClassEngine` — pure function `(chronicle, date) → title`; roster, axis
  mappings, and every threshold in **one table** (`ClassDefinition.roster`),
  exactly like `FocusLevel.ladder`.
- **Extensibility is the acceptance test (pillar 6).** Adding a new activity
  bubble, a new class, or a whole new axis must each be a one-table edit:
  activities declare their axis, classes declare their axis (or axis pair)
  and thresholds, and the engine derives everything else — nothing
  axis-specific is allowed to leak into views or control flow. The Chronicle
  stores raw activity kinds, not axis totals, so old entries re-score
  correctly when mappings or axes change later.
- `BreakRecapView` (its own screen between break and review — a new stop in
  the engine's state flow or a sheet over review, whichever stays lighter),
  `LifestyleQuizView` (one screen after the first review — built last, see
  the §7 build note), and a one-line change to the plan badge.
- Nothing touches `FocusEngine` — the class layer can ship, change, or be
  deleted without entering block logic.

## 12. Edge cases & test plan

`ClassEngine` is a pure function `(chronicle, date) → title`, so every case
below is a plain unit test: build a synthetic Chronicle, ask for the title,
assert. No simulator, no HealthKit, no clock-mocking beyond the `date`
parameter. These ship *with* the feature, not after — the assignment rules
are the product, and the tests are what let tuning (§10 #4, #7, #9) move
numbers without quietly rerouting someone's identity.

**Identity paths**
- Empty chronicle → Novice Wanderer.
- Quiz skipped, focus blocks only → Ascetic within ~a week of daily blocks;
  stays Ascetic (never a hybrid) while no second axis wakes.
- Steady reading/language marks beside the blocks → the epithet dissolves:
  Ascetic → Scholar once focus drops below 60% of Mind marks, held to the
  3-day rule at the boundary (no flapping at 59/61%).
- Epithets never touch hybrids: focus-dominated Mind plus an awake Body is
  still Monk, not "Ascetic-something".
- Focus + exercise quest most days → Monk once the gate is passed; Warrior
  if Body dominates ≥ 1.6×.
- Focus + Hydrate every block → Alchemist is reachable. (Deliberate tuning
  tripwire: if a routine quest alone shouldn't steer the class, this test is
  where the weights get revisited.)
- Late quiz at high level → title unchanged: seed marks are negligible
  against an established chronicle, which is what keeps the "skipping is
  honest" pitch true.
- Late bloomer: Mind-heavy history, then daily Body marks → class shifts
  only after the decay crossover *and* 3 consecutive daily recomputes;
  never flaps mid-shift.

**Gate × ladder interplay**
- Two comparable awake axes below Journeyman → dominant base class only;
  promotion to Journeyman → the hybrid appears immediately, no hysteresis.
- Demotion below Journeyman while holding a hybrid → collapses immediately
  to the dominant base class; re-promotion restores the hybrid.
- Level changes alone (identical chronicle) never change the class half of
  the title.

**Absence (the active-days clock)**
- 9-day gap, then normal life resumes → the title never flips: no active
  days passed while away, and the axes re-wake inside the 3-active-day
  window.
- 90-day gap, same life on return → identical to the 9-day case — title
  held throughout, Chronicle refills, no change ever adopted. No threshold,
  no cliff.
- 90-day gap, *different* life on return → the new portrait lands after
  exactly 3 active days. Absence never changes the class; evidence does.
- Present-but-changed → unaffected by the rule: daily blocks make every day
  active, so drift behaves exactly as the identity-path tests above.

**Math & clock edges**
- Marks at the half-life boundaries (7d, 14d) decay exactly as specified —
  no off-by-one day binning.
- Cross-midnight activity counts for the day it *ended* (same rule as the
  exercise quest).
- Soft cap: ten bubbles tapped in one day → at most 4 marks land on any
  axis.
- Exactly-equal affinities → incumbent keeps the class; fresh ties resolve
  by lifetime marks, then §5 table order. Same input, same title, always.
- All axes fade below the awake bar → Wanderer only after the 3-day hold.

## 13. Depth roadmap (decided, post-v1)

Adopted directions, in rough build order. None block v1; all feed on the
Chronicle that v1 starts writing.

- **The character sheet.** The deferred stats screen done as a proper RPG
  sheet: class art and title, the seven affinities drawn as a spider chart
  (it is literally a character sheet), lifetime stats (blocks, focus hours,
  workouts, coins), and the class history timeline — "Scholar through
  March, Monk all spring, Wizard since June." Every byte already exists in
  the Chronicle.
- **Ceremony.** The first-class award ships in v1 (§9); the roadmap adds
  the rare-moment family — first hybrid, a class held twelve weeks, the
  100th block as an Ascetic. Milestones read from the Chronicle, fire once,
  and are never a streak meter (pillar 4).
- **The codex.** A browsable gallery of all 30 figures: classes you've held
  are painted, unheld ones are parchment silhouettes with their why-line
  shown as a riddle ("Iron and ink…"). Collection depth that provokes "what
  would I have to live like to be a Shaman?" — variety pulled by curiosity,
  never a completion percentage.
- **Class trials** (resolves §10 #5). When a rising second axis puts a new
  class in reach, the quest board may offer a themed trial — "The Wizard
  stirs: two workouts and a sketch this week." Drift made visible and
  chosen; the pursue-a-class pin done with flavor instead of a settings
  toggle.
- **Class voice.** One more roster column: a greeting line per class on the
  plan screen — "The forge is warm" (Blacksmith), "The garden waits"
  (Druid). Pure charm, and proof the data-driven roster pays for itself.
- **Widget & Live Activity.** The title and art on the home screen; during
  a focus block the class figure keeps watch on the lock screen. The class
  system escaping the app with zero new mechanics.
- **A year in the Chronicle.** An annual recap generated locally: blocks
  and focus hours, the classes-held timeline, top activities, the ladder
  journey, coins earned — the year painted as one page of the manual,
  shareable as a card if the player chooses. Free because the Chronicle is
  never pruned (§4).
- **The world bridge (far horizon).** When CONCEPT.md §5B's build-a-world
  hook arrives, classes shape what grows: a Druid's focus raises a grove, a
  Blacksmith's a forge district. Where the label becomes a world-generator.
  Its first acre ships sooner: the Courtyard (CURRENCY.md §4), whose
  fixture catalog is the natural place for class-shaped offerings.

**Deliberate non-goals**, recorded so they aren't re-litigated: mechanical
perks (a class that pays better coins makes self-reports worth lying about —
breaks pillar 5); anything social or leaderboard-shaped (the portrait is
personal; comparison turns lifestyle into competition); and app-usage-derived
classes (iOS exposes no per-app data — opaque labeled-bucket thresholds are
the only legal shape, and screen-time classes cut against the off-screen
thesis).
