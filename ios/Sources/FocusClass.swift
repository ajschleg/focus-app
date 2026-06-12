import Foundation

/// One entry of the class roster: the player-facing name, the ⓘ popover's
/// "why am I this?" line, and placeholder artwork (an SF symbol until the
/// ART.md figure set exists).
struct FocusClass: Equatable {
    let name: String
    let whyLine: String
    let systemImage: String
}

/// The affinity-driven identity, before the ladder gate is applied. This is
/// what hysteresis adopts; rendering it against the current level (hybrids
/// collapse below Journeyman) happens at display time, so gate changes are
/// instant while drift changes are held (CLASSES.md §6 rule 5).
enum ClassVerdict: Equatable, Codable {
    case wanderer
    /// `ascetic` is the focus-dominated epithet; only ever true for `.mind`.
    case base(Axis, ascetic: Bool)
    /// `dominant` carries the stronger axis so a below-gate collapse knows
    /// which base class to show.
    case hybrid(dominant: Axis, partner: Axis)
}

/// THE roster (CLASSES.md §6, names draft): 7 base classes, 21 hybrids,
/// Wanderer, and the Ascetic epithet. A class isn't done without its
/// why-line here and its figure brief in ART.md.
enum ClassRoster {
    static let wanderer = FocusClass(
        name: "Wanderer",
        whyLine: "Every path is still open — no single pursuit has claimed your weeks yet.",
        systemImage: "signpost.right.fill")

    static let ascetic = FocusClass(
        name: "Ascetic",
        whyLine: "Focus itself claims your weeks: block after block of undivided attention.",
        systemImage: "hourglass")

    static let base: [Axis: FocusClass] = [
        .body:   FocusClass(name: "Warrior",
                            whyLine: "Movement claims your weeks: workouts, stretches, active breaks.",
                            systemImage: "dumbbell.fill"),
        .mind:   FocusClass(name: "Scholar",
                            whyLine: "Study claims your weeks: reading, languages, learning.",
                            systemImage: "book.fill"),
        .spirit: FocusClass(name: "Mystic",
                            whyLine: "Stillness claims your weeks: meditation, journaling, quiet.",
                            systemImage: "moon.fill"),
        .craft:  FocusClass(name: "Artisan",
                            whyLine: "Making claims your weeks: drawing, writing, music, craft.",
                            systemImage: "paintbrush.pointed.fill"),
        .heart:  FocusClass(name: "Bard",
                            whyLine: "People claim your weeks: conversation, calls, company.",
                            systemImage: "music.mic"),
        .hearth: FocusClass(name: "Keeper",
                            whyLine: "The home claims your weeks: cooking, tidying, small rituals.",
                            systemImage: "house.fill"),
        .wild:   FocusClass(name: "Druid",
                            whyLine: "Green things claim your weeks: plants, gardens, open air.",
                            systemImage: "camera.macro"),
    ]

    /// The hybrid matrix. Keyed by the unordered pair, so look-ups don't
    /// care which axis dominates.
    static func hybrid(_ a: Axis, _ b: Axis) -> FocusClass {
        let pair = (min(a, b), max(a, b))
        switch pair {
        case (.body, .mind):     return FocusClass(name: "Monk",         whyLine: "Training and study in balance — strong back, sharp mind.",                  systemImage: "figure.mind.and.body")
        case (.body, .spirit):   return FocusClass(name: "Templar",      whyLine: "Sweat beside stillness — you train the body and quiet the mind.",           systemImage: "shield.fill")
        case (.body, .craft):    return FocusClass(name: "Wizard",       whyLine: "Iron and ink — you train hard and you make things.",                        systemImage: "wand.and.stars")
        case (.body, .heart):    return FocusClass(name: "Paladin",      whyLine: "Strength spent on people — you move, and you show up.",                     systemImage: "medal.fill")
        case (.body, .hearth):   return FocusClass(name: "Blacksmith",   whyLine: "Muscle at the hearth — workouts beside house-work.",                        systemImage: "hammer.fill")
        case (.body, .wild):     return FocusClass(name: "Ranger",       whyLine: "Your training lives outdoors — movement among green things.",               systemImage: "figure.hiking")
        case (.mind, .spirit):   return FocusClass(name: "Philosopher",  whyLine: "You learn, then sit with it — study beside reflection.",                    systemImage: "brain.head.profile")
        case (.mind, .craft):    return FocusClass(name: "Artificer",    whyLine: "You learn things, then build them.",                                        systemImage: "gearshape.2.fill")
        case (.mind, .heart):    return FocusClass(name: "Sage",         whyLine: "Learning shared — study beside good company.",                              systemImage: "quote.bubble.fill")
        case (.mind, .hearth):   return FocusClass(name: "Alchemist",    whyLine: "Deep focus, home ritual — study brewed with tea.",                          systemImage: "flask.fill")
        case (.mind, .wild):     return FocusClass(name: "Naturalist",   whyLine: "You study the world, then go walk in it.",                                  systemImage: "binoculars.fill")
        case (.spirit, .craft):  return FocusClass(name: "Calligrapher", whyLine: "Quiet hands, made things — craft beside stillness.",                        systemImage: "signature")
        case (.spirit, .heart):  return FocusClass(name: "Cleric",       whyLine: "Calm given away — stillness beside care for people.",                       systemImage: "hands.and.sparkles.fill")
        case (.spirit, .hearth): return FocusClass(name: "Candlekeeper", whyLine: "Small flames kept lit — quiet ritual at home.",                             systemImage: "flame.fill")
        case (.spirit, .wild):   return FocusClass(name: "Shaman",       whyLine: "Your stillness happens outside — quiet among green things.",                systemImage: "tree.fill")
        case (.craft, .heart):   return FocusClass(name: "Jester",       whyLine: "Made to be shared — your craft happens in company.",                        systemImage: "theatermasks.fill")
        case (.craft, .hearth):  return FocusClass(name: "Tinker",       whyLine: "You fix and make around the house.",                                        systemImage: "wrench.and.screwdriver.fill")
        case (.craft, .wild):    return FocusClass(name: "Herbalist",    whyLine: "Craft from what grows — making beside the garden.",                         systemImage: "leaf.fill")
        case (.heart, .hearth):  return FocusClass(name: "Innkeeper",    whyLine: "A home with people in it — hosting, cooking, company.",                     systemImage: "cup.and.saucer.fill")
        case (.heart, .wild):    return FocusClass(name: "Shepherd",     whyLine: "Company taken outdoors — people and pastures.",                             systemImage: "figure.walk.motion")
        case (.hearth, .wild):   return FocusClass(name: "Homesteader",  whyLine: "You grow it, then you cook it — garden beside kitchen.",                    systemImage: "basket.fill")
        default:
            // Unreachable: the pair is normalized and all 21 cells are
            // listed. Wanderer keeps it total without a crash path.
            return wanderer
        }
    }

    /// Render a verdict against the ladder gate: hybrids need level ≥ 3
    /// (Journeyman); below it, the dominant base class shows — without the
    /// epithet recheck, plain base only.
    static func render(_ verdict: ClassVerdict, levelNumber: Int) -> FocusClass {
        switch verdict {
        case .wanderer:
            return wanderer
        case .base(let axis, let isAscetic):
            return isAscetic ? ascetic : base[axis]!
        case .hybrid(let dominant, let partner):
            return levelNumber >= 3 ? hybrid(dominant, partner) : base[dominant]!
        }
    }
}
