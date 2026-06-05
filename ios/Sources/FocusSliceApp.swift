import SwiftUI

@main
struct FocusSliceApp: App {
    @StateObject private var engine: FocusEngine
    @StateObject private var experience: ExperienceStore
    @StateObject private var coins: CoinStore
    @StateObject private var board: QuestBoard
    @StateObject private var notifier: BlockNotifier

    init() {
        // One shared graph: the engine banks scores into the experience store
        // (XP + the level ladder, which pays promotion rewards into the coin
        // store), the board watches the engine and pays quest rewards into
        // the same coin store, and the notifier handles phase-end alerts.
        let coins = CoinStore()
        let experience = ExperienceStore(coins: coins)
        let notifier = BlockNotifier()
        let engine = FocusEngine(experience: experience, notifier: notifier)
        _experience = StateObject(wrappedValue: experience)
        _coins = StateObject(wrappedValue: coins)
        _notifier = StateObject(wrappedValue: notifier)
        _engine = StateObject(wrappedValue: engine)
        _board = StateObject(wrappedValue: QuestBoard(engine: engine, coins: coins))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(experience)
                .environmentObject(coins)
                .environmentObject(board)
                .environmentObject(notifier)
        }
    }
}
