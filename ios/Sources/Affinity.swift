import Foundation

/// The seven affinity axes (CLASSES.md §5). The raw-value order mirrors the
/// doc's table and serves as the final tie-breaker in class assignment, so
/// reordering cases is a balance change, not a cosmetic one.
enum Axis: Int, CaseIterable, Codable, Comparable {
    case body, mind, spirit, craft, heart, hearth, wild

    static func < (a: Axis, b: Axis) -> Bool { a.rawValue < b.rawValue }
}

/// Everything that can land in the Chronicle. Raw strings are the on-disk
/// format — rename a case freely, never its raw value.
///
/// THE activity table (CLASSES.md pillar 6): an activity's axis, mark
/// weight, and recap label all live in `info`. Adding an activity = one
/// case + one row; the engine and the recap UI derive everything else.
enum ActivityKind: String, Codable, CaseIterable {
    // Automatic signals
    case focusBlock
    case questHydrate, questCleanSweep, questStillness, questExercise
    // Break recap bubbles, grouped by axis
    case exercised, stretched, walked, danced
    case read, language, puzzles, learnedAudio
    case meditated, breathwork, journaled, yoga, didNothing
    case drew, wrote, playedMusic, photography, diy
    case talkedCoworker, calledFriend, playedWithPet, helpedSomeone, volunteered
    case chores, cooked, coffeeTea, errand
    case wateredPlants, gardened, satOutside, hiked, birdwatching
    // The honesty bubble — an active-day signal that feeds no axis.
    case scrolledPhone

    struct Info {
        let axis: Axis?
        /// Mark units dropped on the axis. Verified signals weigh double
        /// (CLASSES.md §5) — currently just the exercise quest.
        let marks: Double
        /// Bubble / receipts label, lowercase past tense.
        let label: String
        /// Whether this appears as a break-recap bubble.
        let inRecap: Bool
    }

    var info: Info { Self.table[self]! }
    var axis: Axis? { info.axis }

    /// All recap bubbles in table order (axis by axis).
    static var recapBubbles: [ActivityKind] { allCases.filter { $0.info.inRecap } }

    private static let table: [ActivityKind: Info] = [
        .focusBlock:     Info(axis: .mind,   marks: 1, label: "focus block",        inRecap: false),
        .questHydrate:   Info(axis: .hearth, marks: 1, label: "hydrated",           inRecap: false),
        .questCleanSweep: Info(axis: .mind,  marks: 1, label: "clean sweep",        inRecap: false),
        .questStillness: Info(axis: .spirit, marks: 1, label: "stillness held",     inRecap: false),
        .questExercise:  Info(axis: .body,   marks: 2, label: "worked out",         inRecap: false),

        .exercised:      Info(axis: .body,   marks: 1, label: "exercised",          inRecap: true),
        .stretched:      Info(axis: .body,   marks: 1, label: "stretched",          inRecap: true),
        .walked:         Info(axis: .body,   marks: 1, label: "walked",             inRecap: true),
        .danced:         Info(axis: .body,   marks: 1, label: "danced",             inRecap: true),

        .read:           Info(axis: .mind,   marks: 1, label: "read",               inRecap: true),
        .language:       Info(axis: .mind,   marks: 1, label: "practiced a language", inRecap: true),
        .puzzles:        Info(axis: .mind,   marks: 1, label: "did a puzzle",       inRecap: true),
        .learnedAudio:   Info(axis: .mind,   marks: 1, label: "learned something",  inRecap: true),

        .meditated:      Info(axis: .spirit, marks: 1, label: "meditated",          inRecap: true),
        .breathwork:     Info(axis: .spirit, marks: 1, label: "breathed",           inRecap: true),
        .journaled:      Info(axis: .spirit, marks: 1, label: "journaled",          inRecap: true),
        .yoga:           Info(axis: .spirit, marks: 1, label: "did yoga",           inRecap: true),
        .didNothing:     Info(axis: .spirit, marks: 1, label: "did nothing",        inRecap: true),

        .drew:           Info(axis: .craft,  marks: 1, label: "drew",               inRecap: true),
        .wrote:          Info(axis: .craft,  marks: 1, label: "wrote",              inRecap: true),
        .playedMusic:    Info(axis: .craft,  marks: 1, label: "played music",       inRecap: true),
        .photography:    Info(axis: .craft,  marks: 1, label: "took photos",        inRecap: true),
        .diy:            Info(axis: .craft,  marks: 1, label: "made something",     inRecap: true),

        .talkedCoworker: Info(axis: .heart,  marks: 1, label: "talked with someone", inRecap: true),
        .calledFriend:   Info(axis: .heart,  marks: 1, label: "called a friend",    inRecap: true),
        .playedWithPet:  Info(axis: .heart,  marks: 1, label: "played with my pet", inRecap: true),
        .helpedSomeone:  Info(axis: .heart,  marks: 1, label: "helped someone",     inRecap: true),
        .volunteered:    Info(axis: .heart,  marks: 1, label: "volunteered",        inRecap: true),

        .chores:         Info(axis: .hearth, marks: 1, label: "did chores",         inRecap: true),
        .cooked:         Info(axis: .hearth, marks: 1, label: "cooked",             inRecap: true),
        .coffeeTea:      Info(axis: .hearth, marks: 1, label: "coffee / tea",       inRecap: true),
        .errand:         Info(axis: .hearth, marks: 1, label: "ran an errand",      inRecap: true),

        .wateredPlants:  Info(axis: .wild,   marks: 1, label: "watered the plants", inRecap: true),
        .gardened:       Info(axis: .wild,   marks: 1, label: "gardened",           inRecap: true),
        .satOutside:     Info(axis: .wild,   marks: 1, label: "sat outside",        inRecap: true),
        .hiked:          Info(axis: .wild,   marks: 1, label: "hiked",              inRecap: true),
        .birdwatching:   Info(axis: .wild,   marks: 1, label: "watched the birds",  inRecap: true),

        .scrolledPhone:  Info(axis: nil,     marks: 0, label: "scrolled my phone",  inRecap: true),
    ]
}
