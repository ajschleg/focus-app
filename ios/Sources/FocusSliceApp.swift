import SwiftUI

@main
struct FocusSliceApp: App {
    @StateObject private var engine: FocusEngine
    @StateObject private var experience: ExperienceStore
    @StateObject private var coins: CoinStore
    @StateObject private var board: QuestBoard
    @StateObject private var notifier: BlockNotifier
    @StateObject private var workouts: WorkoutMonitor

    init() {
        // One shared graph: the engine banks scores into the experience store
        // (XP + the level ladder, which pays promotion rewards into the coin
        // store), the board watches the engine plus the workout monitor
        // (HealthKit) and pays quest rewards into the same coin store, and
        // the notifier handles phase-end alerts.
        let coins = CoinStore()
        let experience = ExperienceStore(coins: coins)
        let notifier = BlockNotifier()
        let workouts = WorkoutMonitor()
        let engine = FocusEngine(experience: experience, notifier: notifier)
        _experience = StateObject(wrappedValue: experience)
        _coins = StateObject(wrappedValue: coins)
        _notifier = StateObject(wrappedValue: notifier)
        _workouts = StateObject(wrappedValue: workouts)
        _engine = StateObject(wrappedValue: engine)
        _board = StateObject(wrappedValue: QuestBoard(engine: engine, coins: coins, workouts: workouts))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(experience)
                .environmentObject(coins)
                .environmentObject(board)
                .environmentObject(notifier)
                .environmentObject(workouts)
        }
    }
}
