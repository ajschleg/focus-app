# FocusSlice — Art direction (Draft for Review)

> Status: **draft — single source of truth for artwork.** CLASSES.md and
> ROADMAP.md point here instead of duplicating. Nothing in this doc is v1
> scope (ROADMAP.md "Art"); the briefs wait for the art pass, whether
> that's hand-drawn or AI-generated.

## 1. The style

**Illuminated-manuscript figures with a modern wink.** Each class is one
full-body figure rendered as a plate from a medieval illuminated manuscript
(or an Elder Scrolls in-game book) — hand-inked woodcut linework with
ink-wash shading, aged vellum ground, no background beyond a soft ground
shadow. The figures wear **medieval dress** (tunics, cloaks, robes, hoods,
simple leather and cloth); the wink is in their *equipment* — every figure
carries a **modern everyday object as fantasy gear** (a dumbbell as a
warhammer, a pour-over rig as an alembic, headphones as a circlet). That
contrast — a properly medieval adventurer holding your real week's objects —
is the system's whole joke (your real week, painted as legend).

*Rendering:* generate in **monochrome sepia** — the app applies one flat
accent color per figure (the class tint) the way `LevelBackground` and the
root `.tint()` already recolor everything, so the figures stay recolorable
and asset-light. Vellum ground in light mode swaps to slate in dark, and the
silhouette must still read at badge size (~84 pt).

## 2. The prompt template

Style guide + brief composed into one prompt, ready for an image model.
Keep it identical across all 30 so the set stays consistent, varying only
the bracketed parts:

> Full-body [CLASS] character plate from an illuminated medieval manuscript:
> [BRIEF]. Figure in medieval dress; the equipment is a modern everyday
> object carried as fantasy gear. Hand-inked woodcut linework with ink-wash
> shading, aged vellum, illuminated-manuscript style, warm monochrome sepia,
> soft ground shadow, strong readable silhouette, centered and fully in
> frame. --style raw --ar 2:3 --s 80 --no color, text, watermark, border,
> frame, busy background, multiple characters, photorealism, modern
> clothing, hoodie, sneakers

The figures are monochrome (the app tints them), so no accent color goes in
the prompt. `--no modern clothing, hoodie, sneakers` keeps the *dress*
medieval while the named object stays modern — that fusion is the point.

Consistency is the hard part of a generated set: reuse the template
verbatim, and where the tool supports it, pin a style reference (the first
accepted image) for the remaining 29.

## 3. Class figure briefs (all DRAFT)

One brief per roster entry (CLASSES.md §6). The roster rule lives there: a
class isn't done without its why-line and its brief here. Clothing
convention: every figure wears medieval dress; where a brief names a modern
garment, read it as the medieval equivalent (a hooded robe, a craftsman's
smock, a tunic). The *object* a figure carries stays modern — that's the
fusion.

| Class | Figure brief |
|---|---|
| Wanderer | Cloaked figure at a fork in the trail, thumbs hooked in daypack straps. |
| Warrior | Guard stance, dumbbell raised like a warhammer, towel cape over one shoulder. |
| Scholar | Perched on a book stack, paperback in hand, flashcards fanned in the belt. |
| Ascetic | Hooded, seated; the phone lies face-down before them like a surrendered blade. |
| Mystic | Cross-legged on a cushion, hood back, breath-steam rising in a slow spiral. |
| Artisan | Leather apron over a tunic, stylus raised like a wand, paint-flecked sleeves. |
| Bard | Phone tucked to shoulder like a fiddle, free hand mid-story, two coffees waiting. |
| Keeper | Broom shouldered like a halberd, keyring at the hip, kettle steaming at the feet. |
| Druid | Watering can held like a censer, vines climbing one sleeve, trowel sheathed. |
| Monk | Hooded monk's robes, wrapped hands, a book tucked into the belt sash. |
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
