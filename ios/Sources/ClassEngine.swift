import Foundation

/// The class system's brain (CLASSES.md §5–§6): pure functions from the
/// Chronicle to a verdict. No state of its own — the adopted class is
/// *derived* by replaying the Chronicle's active days, so there is nothing
/// to migrate or corrupt, and every rule in §12's test plan is a plain
/// unit test.
enum ClassEngine {

    // MARK: - Tuning (every knob in one place)

    /// Affinity at-or-above this is "awake" (≈ four marks this week).
    static let awakeThreshold = 4.0
    /// Runner-up within this fraction of the top axis (both awake) → hybrid.
    static let hybridRatio = 0.6
    /// Mark weight halves every this many days.
    static let halfLifeDays = 7.0
    /// Max mark units one axis can absorb per calendar day (soft cap).
    static let dailyAxisCap = 4.0
    /// Share of Mind that focus blocks must supply for the Ascetic epithet.
    static let epithetShare = 0.6
    /// Consecutive *active* days a new verdict must hold before adoption.
    static let holdActiveDays = 3
    /// The slide back to Wanderer waits longer — longer than a daily-mark
    /// axis needs to re-wake (~5 active days from zero) — so returning to
    /// the same life after any absence never strips the title in passing.
    static let wandererHoldActiveDays = 5
    /// Ladder level (1-based) required to display hybrid classes.
    static let hybridMinLevel = 3
    /// Days of silence after which the ⓘ receipts call the Chronicle quiet.
    static let quietAfterDays = 10.0
    /// Window for the receipts line.
    static let receiptsWindowDays = 14.0

    // MARK: - Affinity

    /// Decay-weighted, daily-capped mark totals per axis, and the same
    /// totals per activity kind (for the epithet share and the receipts).
    /// The cap consumes mark units chronologically within each axis-day —
    /// partial units count, so a 2-mark workout can half-fit.
    static func contributions(entries: [ChronicleEntry], asOf: Date,
                              calendar: Calendar = .current)
        -> (axes: [Axis: Double], kinds: [ActivityKind: Double]) {
        var axes: [Axis: Double] = [:]
        var kinds: [ActivityKind: Double] = [:]

        // Deterministic order matters: float addition isn't associative, so
        // summing in hash order would let two perfectly mirrored axes differ
        // by an ulp and dodge the exact-tie rule. Days sorted, entries
        // chronological — same chronicle, same sums, always.
        let usable = entries.filter { $0.date <= asOf }
        for axis in Axis.allCases {
            let byDay = Dictionary(grouping: usable.filter { $0.kind.axis == axis }) {
                calendar.startOfDay(for: $0.date)
            }
            for (_, group) in byDay.sorted(by: { $0.key < $1.key }) {
                var budget = dailyAxisCap
                for entry in group.sorted(by: { $0.date < $1.date }) {
                    guard budget > 0 else { break }
                    let units = min(entry.kind.info.marks, budget)
                    budget -= units
                    let age = asOf.timeIntervalSince(entry.date)
                    let weight = units * pow(0.5, age / (halfLifeDays * 86_400))
                    axes[axis, default: 0] += weight
                    kinds[entry.kind, default: 0] += weight
                }
            }
        }
        return (axes, kinds)
    }

    // MARK: - Instantaneous verdict

    /// The verdict the affinities support right now — before hysteresis.
    /// `incumbent` matters only for exact ties (rule 6: ties keep the
    /// incumbent, then lifetime marks, then table order).
    static func instantVerdict(entries: [ChronicleEntry], asOf: Date,
                               incumbent: ClassVerdict = .wanderer,
                               calendar: Calendar = .current) -> ClassVerdict {
        let (aff, kinds) = contributions(entries: entries, asOf: asOf, calendar: calendar)

        let incumbentAxes: Set<Axis>
        switch incumbent {
        case .wanderer: incumbentAxes = []
        case .base(let a, _): incumbentAxes = [a]
        case .hybrid(let d, let p): incumbentAxes = [d, p]
        }
        var lifetime: [Axis: Double] = [:]
        for entry in entries where entry.date <= asOf {
            if let axis = entry.kind.axis { lifetime[axis, default: 0] += entry.kind.info.marks }
        }

        let ranked = Axis.allCases.sorted { a, b in
            let (fa, fb) = (aff[a] ?? 0, aff[b] ?? 0)
            if fa != fb { return fa > fb }
            let (ia, ib) = (incumbentAxes.contains(a), incumbentAxes.contains(b))
            if ia != ib { return ia }
            let (la, lb) = (lifetime[a] ?? 0, lifetime[b] ?? 0)
            if la != lb { return la > lb }
            return a < b
        }

        let top = ranked[0]
        let topAff = aff[top] ?? 0
        guard topAff >= awakeThreshold else { return .wanderer }

        let second = ranked[1]
        let secondAff = aff[second] ?? 0
        if secondAff >= awakeThreshold && secondAff >= hybridRatio * topAff {
            return .hybrid(dominant: top, partner: second)
        }

        var ascetic = false
        if top == .mind {
            let mindTotal = aff[.mind] ?? 0
            let focusPart = kinds[.focusBlock] ?? 0
            ascetic = mindTotal > 0 && focusPart / mindTotal >= epithetShare
        }
        return .base(top, ascetic: ascetic)
    }

    // MARK: - Adoption (hysteresis on the active-days clock)

    /// Replay the Chronicle's active days and apply the adoption rules
    /// (CLASSES.md §6): a new verdict must repeat across `holdActiveDays`
    /// consecutive active days; leaving Wanderer is instant; silence never
    /// advances the clock, so absence of any length holds the title.
    static func adoptedVerdict(entries: [ChronicleEntry], asOf: Date,
                               calendar: Calendar = .current) -> ClassVerdict {
        let usable = entries.filter { $0.date <= asOf }.sorted { $0.date < $1.date }
        let activeDays = usable.reduce(into: [Date]()) { days, entry in
            let day = calendar.startOfDay(for: entry.date)
            if days.last != day { days.append(day) }
        }

        var adopted = ClassVerdict.wanderer
        var pending: ClassVerdict?
        var streak = 0

        for day in activeDays {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let reference = min(asOf, dayEnd)
            let upToDay = usable.filter { $0.date <= reference }
            let verdict = instantVerdict(entries: upToDay, asOf: reference,
                                         incumbent: adopted, calendar: calendar)
            if sameTitle(verdict, adopted) {
                // Same player-visible title. Take the fresh verdict anyway:
                // within an adopted hybrid the *dominant* axis may trade
                // places day to day, and the latest one is what a below-gate
                // collapse should show.
                adopted = verdict
                pending = nil
                streak = 0
                continue
            }
            if adopted == .wanderer {
                // The first class lands the moment it's earned.
                adopted = verdict
                pending = nil
                streak = 0
                continue
            }
            if let held = pending, sameTitle(verdict, held) {
                streak += 1
                pending = verdict
            } else {
                pending = verdict
                streak = 1
            }
            let hold = verdict == .wanderer ? wandererHoldActiveDays : holdActiveDays
            if streak >= hold {
                adopted = verdict
                pending = nil
                streak = 0
            }
        }
        return adopted
    }

    /// Whether two verdicts read as the same title to the player. A
    /// hybrid's dominant axis is invisible at the gate (Monk is Monk
    /// whichever axis leads), so the hysteresis hold compares titles —
    /// otherwise day-to-day dominance trades inside one pair would reset
    /// the streak forever. Epithets are part of the title and do differ.
    private static func sameTitle(_ a: ClassVerdict, _ b: ClassVerdict) -> Bool {
        switch (a, b) {
        case (.wanderer, .wanderer):
            return true
        case (.base(let x, let e), .base(let y, let f)):
            return x == y && e == f
        case (.hybrid(let d1, let p1), .hybrid(let d2, let p2)):
            return Set([d1, p1]) == Set([d2, p2])
        default:
            return false
        }
    }

    /// The displayed class: adopted verdict rendered against the ladder
    /// gate (gate changes are instant — rendering, not adoption).
    static func adoptedClass(entries: [ChronicleEntry], asOf: Date,
                             levelNumber: Int,
                             calendar: Calendar = .current) -> (verdict: ClassVerdict, focusClass: FocusClass) {
        let verdict = adoptedVerdict(entries: entries, asOf: asOf, calendar: calendar)
        return (verdict, ClassRoster.render(verdict, levelNumber: levelNumber))
    }

    // MARK: - Receipts (the ⓘ popover's evidence)

    /// Top recent activities behind the verdict's axes, e.g.
    /// ["worked out ×5", "drew ×4", "walked ×3"]. Empty for a Wanderer
    /// with an empty fortnight.
    static func receipts(entries: [ChronicleEntry], asOf: Date,
                         verdict: ClassVerdict) -> [String] {
        let axes: Set<Axis>
        switch verdict {
        case .wanderer: axes = Set(Axis.allCases)
        case .base(let a, _): axes = [a]
        case .hybrid(let d, let p): axes = [d, p]
        }
        let windowStart = asOf.addingTimeInterval(-receiptsWindowDays * 86_400)
        var counts: [ActivityKind: Int] = [:]
        for entry in entries where entry.date > windowStart && entry.date <= asOf {
            if let axis = entry.kind.axis, axes.contains(axis) {
                counts[entry.kind, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key.rawValue < $1.key.rawValue) }
            .prefix(3)
            .map { "\($0.key.info.label) ×\($0.value)" }
    }

    /// True when the Chronicle has gone quiet — the popover says so plainly,
    /// so a title held through absence is transparent, never a lie.
    static func isQuiet(entries: [ChronicleEntry], asOf: Date) -> Bool {
        guard let last = entries.filter({ $0.date <= asOf }).map(\.date).max() else { return true }
        return asOf.timeIntervalSince(last) > quietAfterDays * 86_400
    }

    // MARK: - Recap shelf (which bubbles to show)

    /// The nine visible bubbles (CLASSES.md §7): six most-tapped, two from
    /// the sleepiest axes (the quietest nudge there is), and the honesty
    /// bubble. Fresh chronicles fall back to table order.
    static func recapShelf(entries: [ChronicleEntry], asOf: Date,
                           calendar: Calendar = .current) -> [ActivityKind] {
        var counts: [ActivityKind: Int] = [:]
        for entry in entries where entry.kind.info.inRecap && entry.kind != .scrolledPhone {
            counts[entry.kind, default: 0] += 1
        }
        var shelf = counts.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key.rawValue < $1.key.rawValue) }
            .prefix(6)
            .map(\.key)

        let (aff, _) = contributions(entries: entries, asOf: asOf, calendar: calendar)
        let sleepiest = Axis.allCases.sorted { (aff[$0] ?? 0) < (aff[$1] ?? 0) }
        for axis in sleepiest {
            guard shelf.count < 8 else { break }
            if let bubble = ActivityKind.recapBubbles.first(where: { $0.axis == axis && !shelf.contains($0) }) {
                shelf.append(bubble)
            }
        }
        for bubble in ActivityKind.recapBubbles where shelf.count < 8 {
            if bubble != .scrolledPhone && !shelf.contains(bubble) { shelf.append(bubble) }
        }
        shelf.append(.scrolledPhone)
        return shelf
    }
}
