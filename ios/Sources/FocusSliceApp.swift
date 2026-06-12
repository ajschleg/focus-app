import SwiftUI

@main
struct FocusSliceApp: App {
    @StateObject private var engine: FocusEngine
    @StateObject private var experience: ExperienceStore
    @StateObject private var coins: CoinStore
    @StateObject private var board: QuestBoard
    @StateObject private var notifier: BlockNotifier
    @StateObject private var workouts: WorkoutMonitor
    @StateObject private var chronicle: ChronicleStore
    @StateObject private var classes: ClassStore

    init() {
        // One shared graph: the engine banks scores into the experience store
        // (XP + the level ladder, which pays promotion rewards into the coin
        // store), the board watches the engine plus the workout monitor
        // (HealthKit) and pays quest rewards into the same coin store, the
        // notifier handles phase-end alerts, and the chronicle observes the
        // engine and board to feed the class store's title.
        let coins = CoinStore()
        let experience = ExperienceStore(coins: coins)
        let notifier = BlockNotifier()
        let workouts = WorkoutMonitor()
        let engine = FocusEngine(experience: experience, notifier: notifier)
        let board = QuestBoard(engine: engine, coins: coins, workouts: workouts)
        let chronicle = ChronicleStore()
        chronicle.observe(engine: engine, board: board)
        let classes = ClassStore(chronicle: chronicle, experience: experience)
        _experience = StateObject(wrappedValue: experience)
        _coins = StateObject(wrappedValue: coins)
        _notifier = StateObject(wrappedValue: notifier)
        _workouts = StateObject(wrappedValue: workouts)
        _engine = StateObject(wrappedValue: engine)
        _board = StateObject(wrappedValue: board)
        _chronicle = StateObject(wrappedValue: chronicle)
        _classes = StateObject(wrappedValue: classes)
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
                .environmentObject(chronicle)
                .environmentObject(classes)
        }
    }
}
