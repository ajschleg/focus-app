import Foundation
import Combine
import SwiftUI

/// Base class for everything quest-shaped — the source of focus coins
/// (CONCEPT.md §5A). Subclass it, override the lifecycle hooks you care
/// about, and call `complete()` / `fail()` from them; `QuestBoard` drives the
/// hooks off the engine's published state and pays the reward the moment a
/// quest completes.
///
/// A class (not a protocol) on purpose: quests are stateful little machines
/// that views observe individually, and `@Published status` in a common base
/// is the cheapest way to get that.
class Quest: ObservableObject, Identifiable {
    /// Where the quest surfaces.
    enum Placement {
        case menu      // a row on the plan screen's quest board
        case preFocus  // a prompt sheet when the user taps "Start focus"
        case focus     // springs mid-block on the focus screen
    }

    enum Status {
        case offered    // visible, not yet being judged
        case active     // being judged against the current block
        case completed  // done — reward paid
        case failed     // blown — no reward, shown once in review
    }

    let id = UUID()
    let title: String
    let detail: String
    /// Focus coins paid on completion.
    let reward: Int
    let placement: Placement
    let systemImage: String
    /// The quest's own color, for surfaces it gets to itself (the pre-focus
    /// sheet) — water blue for hydration, etc. nil = follow the level tint.
    let tint: Color?

    /// Self-reported quests are completed by the user tapping "Done" — the
    /// honor-system habits (water, stretching) no sensor can verify.
    var isSelfReported: Bool { false }

    @Published private(set) var status: Status = .offered

    init(title: String, detail: String, reward: Int, placement: Placement,
         systemImage: String, tint: Color? = nil) {
        self.title = title
        self.detail = detail
        self.reward = reward
        self.placement = placement
        self.systemImage = systemImage
        self.tint = tint
    }

    // MARK: - Lifecycle hooks (called by QuestBoard; defaults do nothing)

    /// A focus block just started.
    func focusStarted(template: BlockTemplate) {}

    /// ~Every half second while focusing.
    func focusTicked(elapsed: TimeInterval, remaining: TimeInterval) {}

    /// A distraction was just logged during focus.
    func distractionRecorded(_ event: DistractionEvent) {}

    /// The block reached review — last chance to judge the final state.
    func blockFinished(events: [DistractionEvent], endedEarly: Bool) {}

    // MARK: - Transitions (one-way; a resolved quest never moves again)

    func activate() {
        if status == .offered { status = .active }
    }

    func complete() {
        if status == .offered || status == .active { status = .completed }
    }

    func fail() {
        if status == .offered || status == .active { status = .failed }
    }
}
