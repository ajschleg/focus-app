import Foundation
import Combine
import UIKit

/// Owns the core loop: plan → focus → break prompt → break → review, the
/// countdown timer (which drives both the focus and break phases), and the
/// distraction log built from fused signals (leave-the-app + pickup) during
/// focus. The break is offered, never imposed — focus ends on the prompt, and
/// the user chooses to take or skip it.
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

    /// This block's break length. Equals `template.breakDuration` after a full
    /// focus block, but is shortened when focus is ended early (see `breakLength`).
    @Published private(set) var breakDuration: TimeInterval = 0
    /// Seconds of break actually taken — drives the break credit.
    @Published private(set) var completedBreak: TimeInterval = 0
    /// Whether the break was cut short ("Skip break") rather than run out.
    @Published private(set) var breakEndedEarly: Bool = false

    var leftAppCount: Int { events.lazy.filter { $0.kind == .leftApp }.count }
    var pickupCount: Int { events.lazy.filter { $0.kind == .pickup }.count }

    /// Max points lost for bailing at the very start of a block. The actual
    /// penalty scales linearly with how much of the block you abandon, so
    /// quitting near the end costs little. Loss aversion, used sparingly
    /// (CONCEPT.md §5).
    private let earlyQuitMaxPenalty = 50

    /// Points the break is worth inside the 0–100 block score. You earn these by
    /// actually taking your break; skipping it forfeits them. Folding the break
    /// into the score keeps "100 = a clean block *and* a real break" (CONCEPT.md
    /// §5: reward proper breaks, not just grinding).
    private let breakCreditMax = 20

    /// Break credit earned, 0...breakCreditMax, scaled by how much of the
    /// template's *full* break you actually took. Ending focus early shortens the
    /// break, which caps this — so a clean, complete block is the only path to the
    /// full break credit.
    var breakCredit: Int {
        let full = template.breakDuration
        guard full > 0 else { return breakCreditMax } // no break in template → nothing to forfeit
        let fraction = min(1, max(0, completedBreak / full))
        return Int((Double(breakCreditMax) * fraction).rounded())
    }

    /// Toy score so the review screen has a payoff. Folds focus quality
    /// (distractions + early-quit) and break credit into one 0–100 number —
    /// climbs live as you take the break, final at review. The real reward
    /// economy (CONCEPT.md §5) comes later.
    var score: Int {
        max(0, 100 - leftAppCount * 8 - pickupCount * 4 - earlyQuitPenalty - (breakCreditMax - breakCredit))
    }

    /// What the early-quit penalty would be if you bailed right now. Updates
    /// live during focus so the cost of quitting is never a surprise.
    var potentialEarlyQuitPenalty: Int { penalty(forRemaining: remaining) }

    /// How long the break would be if you ended focus right now — the full break
    /// scaled by the fraction of the block completed. Lets the focus screen show
    /// that quitting early also shortens the break, before it happens.
    var potentialBreakLength: TimeInterval { breakLength(forCompletedFocus: template.focusDuration - remaining) }

    /// The break credit on offer at the break prompt: what `breakCredit` becomes
    /// if the whole offered break is taken. The skip button shows this as the
    /// forfeit (gentle loss aversion, CONCEPT.md §5C).
    var potentialBreakCredit: Int {
        let full = template.breakDuration
        guard full > 0 else { return 0 }
        return Int((Double(breakCreditMax) * min(1, breakDuration / full)).rounded())
    }

    var motionAvailable: Bool { motion.isAvailable }

    private var startDate: Date?
    private var endDate: Date?
    private var ticker: AnyCancellable?
    private var motionSub: AnyCancellable?
    private var lockSub: AnyCancellable?
    private let motion = MotionDetector()
    /// Where finished blocks bank their score (see `enterReview`).
    private let experience: ExperienceStore
    /// Phase-end local notifications, so a locked phone hears the timer.
    private let notifier: BlockNotifier

    /// When iOS last signalled that the device is locking. Locking also
    /// backgrounds the app, so this is how the engine tells "pressed the side
    /// button" apart from "went to the home screen".
    private var lastDeviceLock: Date = .distantPast
    /// How long a backgrounding and a lock signal can be apart and still be
    /// attributed to the same side-button press. Also the length of the
    /// deferred verdict in `sceneWentToBackground`, since the signal usually
    /// lands *after* the backgrounding.
    private let lockGraceWindow: TimeInterval = 2.0

    /// A "left the app" verdict waiting out the grace window (see
    /// `sceneWentToBackground`), plus the background task keeping the app
    /// alive long enough to reach it.
    private var pendingLeftApp: DispatchWorkItem?
    private var pendingLeftAppTask: UIBackgroundTaskIdentifier = .invalid

    init(experience: ExperienceStore = ExperienceStore(), notifier: BlockNotifier = BlockNotifier()) {
        self.experience = experience
        self.notifier = notifier
        motionSub = motion.pickupDetected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.record(.pickup) }

        // Fires when the device locks — on any device that requires a passcode
        // immediately (every Face ID device; nearly all in practice). UIKit
        // posts it on the main thread, shortly *after* the lock has already
        // backgrounded the app — hence cancelling the pending verdict instead
        // of (only) pre-dating it. On a delayed-passcode or passcode-less
        // configuration it may not fire, and a lock degrades to counting as
        // "left the app", the old behavior.
        lockSub = NotificationCenter.default
            .publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)
            .sink { [weak self] _ in
                self?.lastDeviceLock = Date()
                self?.cancelPendingLeftApp()
            }
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
        breakDuration = 0
        completedBreak = 0
        breakEndedEarly = false
        let now = Date()
        startDate = now
        endDate = now.addingTimeInterval(template.focusDuration)
        remaining = template.focusDuration
        state = .focusing

        UIApplication.shared.isIdleTimerDisabled = true   // keep the focus screen (and motion) alive
        motion.start()
        startTicker()
        notifier.scheduleFocusEnd(in: template.focusDuration)
    }

    /// User tapped "End block early" during focus.
    func endBlock() { finishFocus(early: true) }

    /// User accepted the offered break at the prompt.
    func takeBreak() {
        guard state == .breakPrompt else { return }
        startBreak()
    }

    /// User declined the break at the prompt — straight to review, and the
    /// break credit on offer is forfeited (completedBreak stays 0).
    func skipBreak() {
        guard state == .breakPrompt else { return }
        breakEndedEarly = true
        enterReview()
    }

    /// User tapped "Skip break" during the break.
    func endBreak() { finishBreak(early: true) }

    /// Back to the planning screen for another block.
    func reset() {
        UIApplication.shared.isIdleTimerDisabled = false
        notifier.cancelPending()
        state = .planning
        events = []
        completedFocus = 0
        earlyQuitPenalty = 0
        endedEarly = false
        breakDuration = 0
        completedBreak = 0
        breakEndedEarly = false
        startDate = nil
        endDate = nil
        remaining = 0
    }

    /// Called from the scene-phase observer when the app is backgrounded. Only
    /// counts during focus — leaving during a break is fair game (CONCEPT.md §6).
    ///
    /// Locking the phone also backgrounds the app, but putting the phone to
    /// sleep is discipline, not a distraction — skip it. The catch: the lock
    /// signal isn't ordered with the backgrounding by contract, and in
    /// practice lands just *after* it — so the verdict can't be made here.
    /// Instead, hold it for the grace window and let a lock signal cancel it.
    /// The background task keeps the process alive long enough to decide;
    /// without it a lock suspends the app before the signal is even delivered.
    func sceneWentToBackground() {
        let lockSignaled = Date().timeIntervalSince(lastDeviceLock) < lockGraceWindow
        let lockedAlready = !UIApplication.shared.isProtectedDataAvailable
        guard !lockSignaled && !lockedAlready else { return }

        cancelPendingLeftApp() // re-backgrounded inside the window: keep one verdict
        let leftAt = Date()
        let verdict = DispatchWorkItem { [weak self] in self?.commitPendingLeftApp(at: leftAt) }
        pendingLeftApp = verdict
        pendingLeftAppTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            // iOS reclaiming the task before the verdict ran (shouldn't happen —
            // the allowance far exceeds the grace window): no lock signal came,
            // so count the leave rather than drop it.
            self?.commitPendingLeftApp(at: leftAt)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + lockGraceWindow, execute: verdict)
    }

    // MARK: - Private

    private func startTicker() {
        ticker = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    /// One ticker drives whichever phase is running; it reads the wall clock so
    /// the count stays accurate regardless of the 0.5s cadence.
    private func tick() {
        guard let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        switch state {
        case .focusing:
            if left <= 0 {
                remaining = 0
                finishFocus(early: false)
            } else {
                remaining = left
            }
        case .onBreak:
            if left <= 0 {
                remaining = 0
                completedBreak = breakDuration
                finishBreak(early: false)
            } else {
                remaining = left
                completedBreak = min(breakDuration, breakDuration - left)
            }
        default:
            break
        }
    }

    /// Focus ended (naturally or early): record the penalty, size the break from
    /// how much of the block was completed, then offer it at the break prompt.
    private func finishFocus(early: Bool) {
        guard state == .focusing else { return }
        ticker?.cancel(); ticker = nil
        motion.stop()
        // Cancel only on an early end. On a natural finish the trigger has
        // just matured — cancelling would race the delivery daemon and could
        // swallow the legitimate "block complete" banner.
        if early { notifier.cancelPending() }
        if let startDate { completedFocus = Date().timeIntervalSince(startDate) }
        endedEarly = early
        let remainingTime = max(0, template.focusDuration - completedFocus)
        earlyQuitPenalty = early ? penalty(forRemaining: remainingTime) : 0
        breakDuration = breakLength(forCompletedFocus: completedFocus)

        if breakDuration > 0 {
            remaining = 0
            state = .breakPrompt   // the break is offered, not imposed
        } else {
            // Bailed so early there's no break left to earn — go straight to review.
            enterReview()
        }
    }

    /// Starts the break accepted at the prompt. The screen stays awake so the
    /// countdown is glanceable; distraction tracking is off — the break is yours.
    private func startBreak() {
        completedBreak = 0
        let now = Date()
        startDate = now
        endDate = now.addingTimeInterval(breakDuration)
        remaining = breakDuration
        state = .onBreak
        UIApplication.shared.isIdleTimerDisabled = true
        startTicker()
        notifier.scheduleBreakEnd(in: breakDuration)
    }

    private func finishBreak(early: Bool) {
        guard state == .onBreak else { return }
        ticker?.cancel(); ticker = nil
        if early { notifier.cancelPending() }   // see finishFocus: don't race a matured trigger
        if let startDate { completedBreak = min(breakDuration, Date().timeIntervalSince(startDate)) }
        breakEndedEarly = early
        enterReview()
    }

    /// The single exit into review — every block lands here exactly once
    /// (`finishFocus`/`finishBreak` are guarded by state), so this is where the
    /// final score gets banked as experience.
    private func enterReview() {
        UIApplication.shared.isIdleTimerDisabled = false
        remaining = 0
        state = .review
        experience.recordBlock(score: score)
    }

    /// Linear penalty: full `earlyQuitMaxPenalty` if the whole block is left,
    /// scaling to ~0 as the time remaining approaches zero.
    private func penalty(forRemaining remainingTime: TimeInterval) -> Int {
        let total = template.focusDuration
        guard total > 0 else { return 0 }
        let fractionLeft = min(1, max(0, remainingTime) / total)
        return Int((Double(earlyQuitMaxPenalty) * fractionLeft).rounded())
    }

    /// The break scales with the *fraction of the focus block completed*: focus
    /// the whole block and you get the full break; end at the halfway mark and the
    /// break is halved; bail immediately and there's essentially none.
    /// `focused / total` is `focused / (focused + remaining)` — the ratio of time
    /// focused to the time that was on the clock.
    private func breakLength(forCompletedFocus focused: TimeInterval) -> TimeInterval {
        let total = template.focusDuration
        guard total > 0 else { return template.breakDuration }
        let fraction = min(1, max(0, focused / total))
        return template.breakDuration * fraction
    }

    /// The pending verdict came due with no lock signal: it was a real leave,
    /// stamped with when it actually happened, not when the window ran out.
    private func commitPendingLeftApp(at date: Date) {
        guard pendingLeftApp != nil else { return }
        record(.leftApp, at: date)
        cancelPendingLeftApp()
    }

    /// Drop any pending "left the app" verdict and release its background task.
    private func cancelPendingLeftApp() {
        pendingLeftApp?.cancel()
        pendingLeftApp = nil
        if pendingLeftAppTask != .invalid {
            UIApplication.shared.endBackgroundTask(pendingLeftAppTask)
            pendingLeftAppTask = .invalid
        }
    }

    private func record(_ kind: DistractionKind, at date: Date = Date()) {
        guard state == .focusing, let startDate else { return }
        events.append(DistractionEvent(kind: kind, date: date, offset: date.timeIntervalSince(startDate)))
    }
}
