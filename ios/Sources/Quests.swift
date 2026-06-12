import Foundation
import SwiftUI

// The concrete quests. Four patterns so far, one of each:
//  - SelfReportQuest: honor-system menu quest ("Done" button)
//  - CleanSweepQuest: auto-judged menu quest (watches the block's signals)
//  - StillnessQuest:  the mid-block surprise (zero-interaction by design)
//  - ExerciseQuest:   completed by the world outside the app (HealthKit)

/// A quest completed on the honor system — tap "Done" wherever it surfaces
/// (a quest-board row, or the pre-focus prompt sheet). For the healthy habits
/// no sensor can verify: drink water, stretch, clear the desk. Instantiate
/// with whatever title/detail/reward/placement fits.
final class SelfReportQuest: Quest {
    override var isSelfReported: Bool { true }
}

/// Finish the next block with a spotless log — no leaves, no pickups, no
/// early quit. CONCEPT.md §5A's "bonus for a clean block" as a quest.
///
/// Opt-in: it only judges a block if the user tapped Accept (status
/// `.active`) before starting it. Unaccepted, it sits dormant through the
/// block — the `.active` guards matter because the base class allows
/// `complete()`/`fail()` straight from `.offered` (that's how self-report
/// quests work). Once accepted: dies on the first distraction, settles at
/// review.
final class CleanSweepQuest: Quest {
    init() {
        super.init(title: "Clean sweep",
                   detail: "Finish your next block with zero distractions.",
                   reward: 25,
                   placement: .menu,
                   systemImage: "checkmark.seal.fill")
    }

    override func distractionRecorded(_ event: DistractionEvent) {
        if status == .active { fail() }
    }

    override func blockFinished(events: [DistractionEvent], endedEarly: Bool) {
        guard status == .active else { return }   // never accepted — not judged
        endedEarly ? fail() : complete()
    }
}

/// Exercise once today — completed by HealthKit, not by a tap: the moment any
/// workout (watch, Fitness app, Strava, ...) syncs in with today's date, the
/// quest pays out, whatever screen the app is on. It never fails; undone it
/// just carries over, and the break prompt uses it to suggest a walk.
///
/// Once per day: completion stamps the calendar day, and the board only
/// seeds a fresh one on days without a stamp. HealthKit read denials are
/// invisible by design, so a denied quest simply never completes — it stays
/// a standing suggestion to move.
final class ExerciseQuest: Quest {
    override var isAutomatic: Bool { true }

    private static let lastCompletedKey = "quest.exercise.lastCompletedDay"

    /// The once-per-day gate, persisted across launches.
    static func completedToday(defaults: UserDefaults = .standard) -> Bool {
        guard let day = defaults.object(forKey: lastCompletedKey) as? Date else { return false }
        return Calendar.current.isDateInToday(day)
    }

    init() {
        super.init(title: "Move your body",
                   detail: "Finish any workout today. Completes on its own when Health logs one.",
                   reward: 30,
                   placement: .menu,
                   systemImage: "figure.walk",
                   tint: .mint)
    }

    override func workoutLogged(endedAt date: Date) {
        // The monitor can replay yesterday's workout right after midnight —
        // only today's counts.
        guard Calendar.current.isDateInToday(date) else { return }
        complete()
    }

    override func complete() {
        super.complete()
        if status == .completed {
            UserDefaults.standard.set(Date(), forKey: Self.lastCompletedKey)
        }
    }
}

/// The mid-block surprise: pops up at a random point during focus and asks
/// for a stretch of stillness. Deliberately requires *no interaction* — a
/// quest you had to tap would be the distraction it polices; it lives on the
/// focus screen, which stays awake, so it's purely glanceable. Completes when
/// the window runs out (or the block ends first with the challenge unblown);
/// any distraction — or bailing on the block — blows it.
final class StillnessQuest: Quest {
    /// Live countdown for the focus-screen banner.
    @Published private(set) var secondsLeft: Int

    private let duration: TimeInterval
    /// Elapsed-time at which the window closes; anchored on the first tick
    /// after activation so the countdown starts when the banner appears.
    private var deadline: TimeInterval?

    init(duration: TimeInterval, reward: Int) {
        self.duration = duration
        self.secondsLeft = Int(duration.rounded(.up))
        super.init(title: "Stillness check",
                   detail: "Hands off the phone for the next \(Self.lengthString(duration)).",
                   reward: reward,
                   placement: .focus,
                   systemImage: "hand.raised.fill")
    }

    override func focusTicked(elapsed: TimeInterval, remaining: TimeInterval) {
        guard status == .active else { return }
        let deadline = self.deadline ?? elapsed + duration
        self.deadline = deadline
        secondsLeft = max(0, Int((deadline - elapsed).rounded(.up)))
        if elapsed >= deadline { complete() }
    }

    override func distractionRecorded(_ event: DistractionEvent) { fail() }

    override func blockFinished(events: [DistractionEvent], endedEarly: Bool) {
        // Quitting early means hands were on the phone; running the block out
        // with the challenge unblown is stillness held to the end.
        endedEarly ? fail() : complete()
    }

    private static func lengthString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        if m > 0 { return s > 0 ? "\(m)m \(s)s" : "\(m) min" }
        return "\(s)s"
    }
}
