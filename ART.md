# FocusSlice — Art direction (Draft for Review)

> Status: **draft — single source of truth for artwork.** CLASSES.md and
> ROADMAP.md point here instead of duplicating. Nothing in this doc is v1
> scope (ROADMAP.md "Art"); the briefs wait for the art pass, whether
> that's hand-drawn or AI-generated.

## 1. The style — undecided

The rendering style is being chosen; nothing here locks it. What's fixed is
independent of style:

- **One full-body figure per class**, centered and fully in frame, no
  background beyond a soft ground shadow.
- **The modern-object fusion** (content, not style): every figure carries a
  modern everyday object as fantasy gear — a dumbbell as a warhammer, a
  pour-over rig as an alembic, headphones as a circlet. This is the class
  system's whole joke (your real week, painted as legend) and holds whatever
  the rendering turns out to be.
- **Reads at badge size** (~84 pt) and **works in light and dark mode**.

Open questions to settle before drawing: the medium (ink wash, woodcut,
painterly, flat vector, pixel, …); the dress (period or modern); and whether
to generate **monochrome** so the app applies the class tint (recolorable,
asset-light, the way `LevelBackground` and the root `.tint()` already work)
or commit to **full color** per figure. Fold the answers into §2 once
chosen.

## 2. The prompt template

A skeleton for whatever image model you use. Fill `[STYLE]` once §1's open
questions are settled, then keep it identical across all 30 so the set stays
consistent, varying only the bracketed parts:

> Full-body [CLASS] figure: [BRIEF]. [STYLE — medium, dress, palette]. Soft
> ground shadow, strong readable silhouette, centered and fully in frame. No
> text, no watermark, no busy background, no multiple figures.

Consistency is the hard part of a generated set: reuse the template
verbatim, and where the tool supports it (e.g. Midjourney `--sref`), pin a
style reference (the first accepted image) for the remaining 29.

Consistency is the hard part of a generated set: reuse the template
verbatim, and where the tool supports it, pin a style reference (the first
accepted image) for the remaining 29.

## 3. Class figure briefs (all DRAFT)

One brief per roster entry (CLASSES.md §6). The roster rule lives there: a
class isn't done without its why-line and its brief here. The briefs are
pose + object only — the rendering medium and dress are set in §2 once the
style is chosen.

| Class | Figure brief |
|---|---|
| Wanderer | Cloaked figure at a fork in the trail, thumbs hooked in daypack straps. |
| Warrior | Guard stance, dumbbell raised like a warhammer, towel cape over one shoulder. |
| Scholar | Perched on a book stack, paperback in hand, flashcards fanned in the belt. |
| Ascetic | Hooded, seated; the phone lies face-down before them like a surrendered blade. |
| Mystic | Cross-legged on a cushion, hood back, breath-steam rising in a slow spiral. |
| Artisan | Apron, stylus raised like a wand, paint-flecked sleeves. |
| Bard | Phone tucked to shoulder like a fiddle, free hand mid-story, two coffees waiting. |
| Keeper | Broom shouldered like a halberd, keyring at the hip, kettle steaming at the feet. |
| Druid | Watering can held like a censer, vines climbing one sleeve, trowel sheathed. |
| Monk | Robes, wrapped hands, a book tucked into the belt sash. |
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
Levels.swift), so swapping in real art is a one-table edit. Direction:
emblems rather than figures (a rank is a badge, not a person), in the same
style as the class figures once that's chosen; each keeps its existing tint.
Per-rank briefs not yet drafted.

## 5. App icon (exists)

Saffron disc on indigo, diagonally sliced with the halves sheared apart — a
1024 px PNG generated by `ios/Tools/make-app-icon.swift` (constants at the
top; rerun with `swift ios/Tools/make-app-icon.swift`). Predates this style
guide; revisit for consistency once the figure set exists.

## 6. The Courtyard (code-drawn, no assets)

The coin sink's scene (CURRENCY.md §4) is deliberately **not** illustration
work: a parametric SwiftUI drawing — flat shapes drawn in code, one accent
color (the level tint), light/dark aware — per the app-icon-script
precedent, echoing the class-art style once it's chosen. Fixtures render in
code with slight variation seeded by purchase date. If the figure set ever
raises the bar, the Courtyard can graduate to real illustration without
touching mechanics.
