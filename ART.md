# FocusSlice — Art direction (Draft for Review)

> Status: **draft — single source of truth for artwork.** CLASSES.md and
> ROADMAP.md point here instead of duplicating. Nothing in this doc is v1
> scope (ROADMAP.md "Art"); the briefs wait for the art pass, whether
> that's hand-drawn or AI-generated.

## 1. The style

**Oblivion-manual figures, modernized.** Each class is one full-body figure
in a loose ink-and-wash sketch — warm sepia line, visible brushwork, no
background beyond a ground shadow — like a page from a worn RPG manual. The
modern touch is twofold. *Rendering:* clean linework over the wash, exactly
one flat accent color per figure (the class's tint), parchment ground in
light mode swapping to slate in dark, and a silhouette that still reads at
badge size (~84 pt). *Subject:* every figure strikes a fantasy pose while
holding modern life — that's the system's whole joke (your real week,
painted as legend), so the art carries it too.

## 2. The prompt template

Style guide + brief composed into one prompt, ready for an image model.
Keep it identical across all 30 so the set stays consistent, varying only
the bracketed parts:

> Full-body [CLASS] figure: [BRIEF]. Loose ink-and-wash character study in
> the style of a worn RPG manual page — warm sepia linework, visible
> brushwork, aged-parchment background, soft ground shadow, no other
> scenery. A single flat [TINT] accent color. Modern everyday objects
> carried as fantasy equipment. Strong readable silhouette, figure centered
> and fully in frame. No photorealism, no full color, no text, no busy
> background.

Consistency is the hard part of a generated set: reuse the template
verbatim, and where the tool supports it, pin a style reference (the first
accepted image) for the remaining 29.

## 3. Class figure briefs (all DRAFT)

One brief per roster entry (CLASSES.md §6). The roster rule lives there: a
class isn't done without its why-line and its brief here.

| Class | Figure brief |
|---|---|
| Wanderer | Cloaked figure at a fork in the trail, thumbs hooked in daypack straps. |
| Warrior | Guard stance, dumbbell raised like a warhammer, towel cape over one shoulder. |
| Scholar | Perched on a book stack, paperback in hand, flashcards fanned in the belt. |
| Ascetic | Hooded, seated; the phone lies face-down before them like a surrendered blade. |
| Mystic | Cross-legged on a cushion, hood back, breath-steam rising in a slow spiral. |
| Artisan | Apron over street clothes, stylus raised like a wand, paint-flecked sleeves. |
| Bard | Phone tucked to shoulder like a fiddle, free hand mid-story, two coffees waiting. |
| Keeper | Broom shouldered like a halberd, keyring at the hip, kettle steaming at the feet. |
| Druid | Watering can held like a censer, vines climbing one sleeve, trowel sheathed. |
| Monk | Hoodie worn as robes, wrapped hands, a book tucked into the belt sash. |
| Templar | Yoga mat slung as a kite shield, water-bottle mace at the belt. |
| Wizard | Brush raised like a staff, headphones for a circlet, gym-bag familiar at heel. |
| Paladin | Race medal worn as the holy amulet, one arm hauling a second figure up. |
| Blacksmith | Oven-mitt gauntlets, cast-iron skillet raised like a smith's hammer. |
| Ranger | Trail shoes, hiking poles quivered across the back, map half-folded. |
| Philosopher | Chin on fist, paperback splayed on one knee, eyes somewhere past the page. |
| Artificer | Multitool in hand, half-built gadget, schematics curling like scrolls. |
| Sage | One finger marking a page, the other hand mid-explanation to a friend. |
| Alchemist | Pour-over rig as an alembic, steam curling into faint runes. |
| Naturalist | Field journal open, magnifying glass raised, fern pressed between pages. |
| Calligrapher | Brush poised over blank paper, ink stone beside, perfectly still. |
| Cleric | Offering a steaming mug with both hands, like a sacrament. |
| Candlekeeper | Lighting a windowsill candle, dish towel over the shoulder. |
| Shaman | Barefoot on grass, eyes closed, trowel staked beside them like a staff. |
| Jester | Marker behind each ear, sketchbook held up to an unseen crowd, mid-grin. |
| Tinker | Kneeling at a mended chair, tool roll unfurled like a campaign map. |
| Herbalist | Herbs drying on a line overhead, pruning shears holstered at the hip. |
| Innkeeper | Tray of two mugs held high, towel over the forearm, door open behind. |
| Shepherd | Crook-like walking stick, dog at heel, hills rolling behind. |
| Homesteader | Vegetable basket on the hip, wooden spoon sheathed in the apron like a dagger. |

## 4. Ladder rank art (briefs TBD)

The ten guild ranks (Novice → Paragon) currently wear placeholder SF
symbols and tints — both live in `FocusLevel.ladder` (ios/Sources/
Levels.swift), so swapping in real art is a one-table edit. Direction: the
same ink-and-wash family as the class figures, but emblems rather than
figures (a rank is a badge, not a person); each keeps its existing tint as
the accent. Per-rank briefs not yet drafted.

## 5. App icon (exists)

Saffron disc on indigo, diagonally sliced with the halves sheared apart — a
1024 px PNG generated by `ios/Tools/make-app-icon.swift` (constants at the
top; rerun with `swift ios/Tools/make-app-icon.swift`). Predates this style
guide; revisit for consistency once the figure set exists.

## 6. The Courtyard (code-drawn, no assets)

The coin sink's scene (CURRENCY.md §4) is deliberately **not** illustration
work: a parametric SwiftUI drawing in this guide's family — flat shapes,
ink-line feel, one accent color (the level tint), light/dark aware — per
the app-icon-script precedent. Fixtures render in code with slight
variation seeded by purchase date. If the figure set ever raises the bar,
the Courtyard can graduate to real illustration without touching mechanics.
