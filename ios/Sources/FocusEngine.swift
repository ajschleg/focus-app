import Foundation
import Combine
import UIKit

/// Owns the core loop: plan → focus → review, the countdown timer, and the
/// distraction log built from fused signals (leave-the-app + pickup).
///
/// All mutation happens on the main queue (timer publishes on `.main`, the
/// motion subscription hops to `.main`, and the scene-phase + button callbacks
/// are already on `.main`), so `@Published` updates are main-thread safe.
final class FocusEngine: ObservableObject {
    @Published private(set) var state: SessionState = .planning
    @Published private(set) var template: BlockTemplate = BlockTemplate.presets[2] // Classic 50/10
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var events: [DistractionEvent] = []
    @Published private(set) var completedFocus: TimeInterval = 0
    @Published private(set) var endedEarly: Bool = false
    @Published private(set) var earlyQuitPenalty: Int = 0

    var leftAppCount: Int { events.lazy.filter { $0.kind == .leftApp }.count }
    var pickupCount: Int { events.lazy.filter { $0.kind == .pickup }.count }

    /// Max points lost for bailing at the very start of a block. The actual
    /// penalty scales linearly with how much of the block you abandon, so
    /// quitting near the end costs little. Loss aversion, used sparingly
    /// (CONCEPT.md §5).
    private let earlyQuitMaxPenalty = 50

    /// Toy score so the review screen has a payoff. Purely to make the loop
    /// feel real — the real reward economy (CONCEPT.md §5) comes later.
    var score: Int { max(0, 100 - leftAppCount * 8 - pickupCount * 4 - earlyQuitPenalty) }

    /// What the early-quit penalty would be if you bailed right now. Updates
    /// live during focus so the cost of quitting is never a surprise.
    var potentialEarlyQuitPenalty: Int { penalty(forRemaining: remaining) }

    var motionAvailable: Bool { motion.isAvailable }

    private var startDate: Date?
    private var endDate: Date?
    private var ticker: AnyCancellable?
    private var motionSub: AnyCancellable?
    private let motion = MotionDetector()

    init() {
        motionSub = motion.pickupDetected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.record(.pickup) }
    }

    func select(_ template: BlockTemplate) {
        guard state == .planning else { return }
        self.template = template
    }

    func startFocus() {
        guard state == .planning else { return }
        events = []
        completedFocus = 0
        earlyQuitPenalty = 0
        endedEarly = false
        let now = Date()
        startDate = now
        endDate = now.addingTimeInterval(template.focusDuration)
        remaining = template.focusDuration
        state = .focusing

        UIApplication.shared.isIdleTimerDisabled = true   // keep the focus screen (and motion) alive
        motion.start()
        ticker = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    /// User tapped "End block early".
    func endBlock() { finish(early: true) }

    /// Back to the planning screen for another block.
    func reset() {
        UIApplication.shared.isIdleTimerDisabled = false
        state = .planning
        events = []
        completedFocus = 0
        earlyQuitPenalty = 0
        endedEarly = false
        startDate = nil
        endDate = nil
        remaining = 0
    }

    /// Called from the scene-phase observer when the app is backgrounded.
    func sceneWentToBackground() {
        record(.leftApp)
    }

    // MARK: - Private

    private func tick() {
        guard let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        if left <= 0 {
            remaining = 0
            finish(early: false)
        } else {
            remaining = left
        }
    }

    private func finish(early: Bool) {
        guard state == .focusing else { return }
        ticker?.cancel(); ticker = nil
        motion.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        if let startDate { completedFocus = Date().timeIntervalSince(startDate) }
        endedEarly = early
        let remainingTime = max(0, template.focusDuration - completedFocus)
        earlyQuitPenalty = early ? penalty(forRemaining: remainingTime) : 0
        remaining = 0
        state = .review
    }

    /// Linear penalty: full `earlyQuitMaxPenalty` if the whole block is left,
    /// scaling to ~0 as the time remaining approaches zero.
    private func penalty(forRemaining remainingTime: TimeInterval) -> Int {
        let total = template.focusDuration
        guard total > 0 else { return 0 }
        let fractionLeft = min(1, max(0, remainingTime) / total)
        return Int((Double(earlyQuitMaxPenalty) * fractionLeft).rounded())
    }

    private func record(_ kind: DistractionKind) {
        guard state == .focusing, let startDate else { return }
        let now = Date()
        events.append(DistractionEvent(kind: kind, date: now, offset: now.timeIntervalSince(startDate)))
    }
}
