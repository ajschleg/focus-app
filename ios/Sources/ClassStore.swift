import Foundation
import Combine

/// Publishes the adopted class for the UI and owns the two announcement
/// moments (CLASSES.md §9): the one-time first-class ceremony and the quiet
/// "your path has shifted" card. All judgment lives in `ClassEngine` — this
/// store just recomputes when the Chronicle or the ladder move.
final class ClassStore: ObservableObject {
    @Published private(set) var verdict: ClassVerdict = .wanderer
    @Published private(set) var current: FocusClass = ClassRoster.wanderer
    /// Non-nil while the first-class ceremony waits to be seen. Set the day
    /// Wanderer ends, persisted until dismissed so a missed launch still
    /// gets its moment.
    @Published private(set) var ceremony: FocusClass?
    /// The quiet drift card: previous announced name → current. Sticks
    /// around (across launches) until dismissed.
    @Published private(set) var shift: (from: String, to: String)?

    private let chronicle: ChronicleStore
    private let experience: ExperienceStore
    private let defaults: UserDefaults
    private var subs = Set<AnyCancellable>()

    private static let ceremonyShownKey = "class.ceremonyShown"
    private static let announcedKey = "class.announcedName"

    init(chronicle: ChronicleStore, experience: ExperienceStore,
         defaults: UserDefaults = .standard) {
        self.chronicle = chronicle
        self.experience = experience
        self.defaults = defaults

        // $entries replays on subscribe, so this also computes the initial
        // title. The experience hop through main defers one runloop so the
        // ladder's new value is in place when we read levelNumber.
        chronicle.$entries
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &subs)
        experience.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &subs)
    }

    /// Recompute from the Chronicle. Called on every new entry, on ladder
    /// movement, and when the app foregrounds (a new day may have dawned).
    func refresh(asOf: Date = Date()) {
        #if DEBUG
        if debugSelection != nil { return }   // a forced class stands until cleared
        #endif
        let result = ClassEngine.adoptedClass(entries: chronicle.entries, asOf: asOf,
                                              levelNumber: experience.levelNumber)
        verdict = result.verdict
        current = result.focusClass

        let announced = defaults.string(forKey: Self.announcedKey) ?? ClassRoster.wanderer.name
        guard current.name != announced else { return }
        if verdict != .wanderer && !defaults.bool(forKey: Self.ceremonyShownKey) {
            // The day Wanderer ends gets the full-screen moment, not a card.
            ceremony = current
        } else {
            shift = (from: announced, to: current.name)
        }
    }

    // MARK: - The ⓘ popover's evidence

    var receipts: [String] {
        ClassEngine.receipts(entries: chronicle.entries, asOf: Date(), verdict: verdict)
    }

    /// A long-quiet Chronicle is said out loud, so a title held through
    /// absence (rule 4) is transparent, never a lie.
    var isQuiet: Bool {
        ClassEngine.isQuiet(entries: chronicle.entries, asOf: Date())
    }

    // MARK: - Announcement lifecycle

    func ceremonySeen() {
        defaults.set(true, forKey: Self.ceremonyShownKey)
        defaults.set(current.name, forKey: Self.announcedKey)
        ceremony = nil
    }

    func shiftSeen() {
        defaults.set(current.name, forKey: Self.announcedKey)
        shift = nil
    }

    #if DEBUG
    // MARK: - Debug roster switcher (stripped from release builds)

    /// The forced class, if any. While set, `refresh()` is inert so chronicle
    /// changes can't clobber the selection — purely for art-testing the set.
    @Published private(set) var debugSelection: FocusClass?

    func debugSet(_ focusClass: FocusClass) {
        debugSelection = focusClass
        current = focusClass
    }

    /// Drop the override and recompute the real class from the Chronicle.
    func debugClear() {
        debugSelection = nil
        refresh()
    }
    #endif
}
