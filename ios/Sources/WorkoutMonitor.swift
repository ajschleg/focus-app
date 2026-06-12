import Foundation
import HealthKit

/// Watches HealthKit for finished workouts — the signal behind the daily
/// exercise quest. Any workout type counts; whatever the watch, the Fitness
/// app, or a third-party tracker saves shows up the same way.
///
/// Read authorization is asked lazily on `start()` (the board calls it when
/// it seeds an exercise quest), so the system sheet appears the first time
/// the quest exists, not at install. HealthKit hides read denials — a denied
/// app just sees no samples — so there is no "denied" state to surface; the
/// quest simply never auto-completes.
final class WorkoutMonitor: ObservableObject {
    /// End date of the most recent workout that ended today, if any.
    /// Published on the main thread.
    @Published private(set) var lastWorkoutEnd: Date?

    private let store = HKHealthStore()
    private var started = false

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Idempotent. The first call requests read permission, starts the
    /// observer, and enables background delivery so a workout syncing in
    /// while the app naps still lands the same day.
    func start() {
        guard !started, isAvailable else { return }
        started = true
        store.requestAuthorization(toShare: nil, read: [HKObjectType.workoutType()]) { [weak self] ok, _ in
            // ok is false only if the request itself failed — a read *denial*
            // still returns true (HealthKit keeps denials invisible).
            guard ok else { return }
            self?.observeWorkouts()
            self?.refresh()
        }
    }

    /// Re-query today's workouts. Cheap — runs on observer fires and app
    /// foregrounding (a watch workout may have synced in while we slept).
    func refresh() {
        guard started else { return }
        // Overlap with [startOfToday, ∞) is exactly "ended today or later":
        // a cross-midnight workout still counts for the day it ended.
        let endedToday = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()), end: nil)
        let newestFirst = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: endedToday,
                                  limit: 1, sortDescriptors: [newestFirst]) { [weak self] _, samples, _ in
            guard let end = (samples?.first as? HKWorkout)?.endDate else { return }
            DispatchQueue.main.async { self?.lastWorkoutEnd = end }
        }
        store.execute(query)
    }

    private func observeWorkouts() {
        let query = HKObserverQuery(sampleType: .workoutType(), predicate: nil) { [weak self] _, done, _ in
            self?.refresh()
            done()
        }
        store.execute(query)
        // Wake the app when a workout saves while we're backgrounded (the
        // watch finishing a walk mid-break) so the quest completes — and pays —
        // the moment it syncs, not at the next open. Requires the
        // background-delivery entitlement; if that's ever missing the call
        // fails quietly and the foreground refresh still catches up.
        store.enableBackgroundDelivery(for: .workoutType(), frequency: .immediate) { _, _ in }
    }
}
