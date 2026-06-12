import Foundation
import Combine

/// Runs the quest layer: keeps the plan screen stocked with offers, relays
/// the engine's signals into each quest's lifecycle hooks, springs the
/// mid-block surprise, and pays focus coins on completion.
///
/// The engine knows nothing about quests — the board observes its published
/// state from the outside, so quests can grow without touching block logic.
final class QuestBoard: ObservableObject {
    /// The current cycle's quests, every status. Resolved ones stick around
    /// for the review screen and are swept when planning resumes.
    @Published private(set) var quests: [Quest] = []

    var menuQuests: [Quest] { quests.filter { $0.placement == .menu } }
    var focusQuest: Quest? { quests.first { $0.placement == .focus } }
    /// The quest to surface when the user taps "Start focus" — a nudge at the
    /// moment it's actionable, not a permanent row on the plan screen. Only
    /// an unresolved offer prompts; a skipped one carries over and prompts
    /// again next block.
    var preFocusQuest: Quest? {
        quests.first { $0.placement == .preFocus && $0.status == .offered }
    }
    /// Quests with a verdict, for the review screen.
    var resolvedQuests: [Quest] { quests.filter { $0.status == .completed || $0.status == .failed } }
    /// This cycle's exercise quest, if one is in play — the break prompt
    /// nudges a walk while it's open and confirms once the workout lands.
    var exerciseQuest: Quest? { quests.first { $0 is ExerciseQuest } }
    /// Coins paid out this cycle — the review screen's payoff line.
    var coinsEarnedThisCycle: Int {
        quests.lazy.filter { $0.status == .completed }.reduce(0) { $0 + $1.reward }
    }

    /// Chance a stillness check springs during a block. Pinned to "always"
    /// while the slice is being tuned — drop it once surprise should mean
    /// surprise.
    private let surpriseChance = 1.0
    /// When the surprise may fire, as a fraction of the block elapsed.
    private let surpriseWindow = 0.2...0.5
    private let surpriseReward = 10
    /// Surprise length: up to 5 minutes, never more than half the time left.
    private let surpriseMaxDuration: TimeInterval = 5 * 60

    private let engine: FocusEngine
    private let coins: CoinStore
    /// HealthKit workouts, feeding the daily exercise quest.
    private let workouts: WorkoutMonitor
    private var subs = Set<AnyCancellable>()
    /// One payout watcher per adopted quest, dropped when the quest is swept.
    private var payoutSubs = [UUID: AnyCancellable]()
    private var seenEventCount = 0
    /// Elapsed-time at which this block's surprise fires, if one is scheduled.
    private var surpriseAt: TimeInterval?

    init(engine: FocusEngine, coins: CoinStore, workouts: WorkoutMonitor) {
        self.engine = engine
        self.coins = coins
        self.workouts = workouts

        // $state replays its current value on subscribe, so this also seeds
        // the initial offers (the engine starts in .planning).
        engine.$state
            .removeDuplicates()
            .sink { [weak self] state in self?.stateChanged(to: state) }
            .store(in: &subs)

        engine.$events
            .sink { [weak self] events in self?.eventsChanged(events) }
            .store(in: &subs)

        engine.$remaining
            .sink { [weak self] remaining in self?.ticked(remaining: remaining) }
            .store(in: &subs)

        // The monitor publishes on the main thread and replays its current
        // value, so a workout found before this subscription still lands
        // (the $state replay above has already seeded the quests).
        workouts.$lastWorkoutEnd
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] end in self?.quests.forEach { $0.workoutLogged(endedAt: end) } }
            .store(in: &subs)
    }

    /// Daily offers can change without a state transition — midnight can pass
    /// while the app sits on the plan screen — so the foreground observer
    /// re-checks them.
    func refreshOffers() {
        guard engine.state == .planning else { return }
        seedMenuOffers()
    }

    /// User tapped "Done" on a self-reported quest.
    func reportDone(_ quest: Quest) {
        guard quest.isSelfReported else { return }
        quest.complete()
    }

    /// User tapped "Accept" on an auto-judged challenge — quests don't apply
    /// to a block unless taken on deliberately. One-way for the cycle; a
    /// resolved quest is swept and a fresh offer appears next planning.
    func accept(_ quest: Quest) {
        guard !quest.isSelfReported else { return }
        quest.activate()
    }

    // MARK: - Engine relay

    private func stateChanged(to state: SessionState) {
        switch state {
        case .planning:
            sweep()
            seedMenuOffers()
        case .focusing:
            scheduleSurprise()
            quests.forEach { $0.focusStarted(template: engine.template) }
        case .review:
            quests.forEach { $0.blockFinished(events: engine.events, endedEarly: engine.endedEarly) }
        case .breakPrompt, .onBreak:
            break
        }
    }

    private func eventsChanged(_ events: [DistractionEvent]) {
        if events.count < seenEventCount { seenEventCount = events.count } // new block reset
        guard events.count > seenEventCount else { return }
        let fresh = events[seenEventCount...]
        seenEventCount = events.count
        fresh.forEach { event in quests.forEach { $0.distractionRecorded(event) } }
    }

    private func ticked(remaining: TimeInterval) {
        guard engine.state == .focusing else { return }
        let elapsed = engine.template.focusDuration - remaining
        quests.forEach { $0.focusTicked(elapsed: elapsed, remaining: remaining) }
        springSurpriseIfDue(elapsed: elapsed, remaining: remaining)
    }

    // MARK: - The mid-block surprise

    private func scheduleSurprise() {
        surpriseAt = nil
        guard Double.random(in: 0..<1) < surpriseChance else { return }
        surpriseAt = engine.template.focusDuration * Double.random(in: surpriseWindow)
    }

    private func springSurpriseIfDue(elapsed: TimeInterval, remaining: TimeInterval) {
        guard let at = surpriseAt, elapsed >= at else { return }
        surpriseAt = nil
        // Never spring a challenge the block can't meaningfully fit.
        let duration = min(surpriseMaxDuration, remaining / 2)
        guard duration >= 15 else { return }
        let quest = StillnessQuest(duration: duration, reward: surpriseReward)
        adopt(quest)
        quest.activate()
    }

    // MARK: - Bookkeeping

    private func adopt(_ quest: Quest) {
        // Pay the moment the status lands on .completed, whichever hook (or
        // "Done" tap) put it there; `first` guarantees a single payout.
        payoutSubs[quest.id] = quest.$status
            .first { $0 == .completed }
            .sink { [weak self] _ in self?.coins.earn(quest.reward) }
        quests.append(quest)
    }

    /// Drop resolved quests (their review showing is over) and any leftover
    /// focus quest — surprises don't carry across blocks.
    private func sweep() {
        quests.removeAll { $0.status == .completed || $0.status == .failed || $0.placement == .focus }
        let alive = Set(quests.map(\.id))
        payoutSubs = payoutSubs.filter { alive.contains($0.key) }
    }

    /// Keep the cycle stocked: one healthy pre-focus nudge plus one
    /// clean-block challenge. Unresolved offers carry over as-is.
    private func seedMenuOffers() {
        if !quests.contains(where: { $0 is SelfReportQuest }) {
            adopt(SelfReportQuest(title: "Hydrate",
                                  detail: "Drink a glass of water before this block.",
                                  reward: 5,
                                  placement: .preFocus,
                                  systemImage: "drop.fill",
                                  tint: .blue))
        }
        if !quests.contains(where: { $0 is CleanSweepQuest }) {
            adopt(CleanSweepQuest())
        }
        // One workout a day: only seeded on days it hasn't been earned yet.
        // Starting the monitor here keeps the HealthKit permission sheet tied
        // to the quest's first appearance rather than app install.
        if workouts.isAvailable, !ExerciseQuest.completedToday(),
           !quests.contains(where: { $0 is ExerciseQuest }) {
            adopt(ExerciseQuest())
            workouts.start()
        }
    }
}
