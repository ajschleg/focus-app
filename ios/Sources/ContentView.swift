import SwiftUI

/// Routes between the three states of the core loop and wires up the
/// leave-the-app signal via `scenePhase`.
struct ContentView: View {
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var experience: ExperienceStore
    @EnvironmentObject private var notifier: BlockNotifier
    @EnvironmentObject private var board: QuestBoard
    @EnvironmentObject private var workouts: WorkoutMonitor
    @EnvironmentObject private var classes: ClassStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch engine.state {
            case .planning:    PlanView()
            case .focusing:    FocusView()
            case .breakPrompt: BreakPromptView()
            case .onBreak:     BreakView()
            case .review:      ReviewView()
            }
        }
        // The current class's artwork is the app's backdrop (scrimmed for
        // legibility); accents still follow the ladder tint. Classes without
        // art fall back to the level-tint wash.
        .background(ClassBackground(focusClass: classes.current, tint: experience.level.tint))
        .tint(experience.level.tint)
        // Cross-fade when a promotion/demotion or a class change lands.
        .animation(.easeInOut(duration: 0.8), value: experience.levelIndex)
        .animation(.easeInOut(duration: 0.8), value: classes.current.name)
        .onChange(of: scenePhase) { _, newPhase in
            // Going to .background while focusing is the "I got distracted /
            // left the app" signal (no entitlement needed). The engine filters
            // out backgrounding caused by locking the phone — that's
            // discipline, not a distraction.
            if newPhase == .background, engine.state == .focusing {
                engine.sceneWentToBackground()
            }
            // Coming back to the foreground: re-read notification permission
            // in case the user just flipped it in Settings, catch any workout
            // that synced in while we slept, and re-check the daily offers
            // (midnight may have passed).
            if newPhase == .active {
                notifier.refreshStatus()
                workouts.refresh()
                board.refreshOffers()
                classes.refresh()   // a new day may have dawned on the title
            }
        }
    }
}

/// The current class's artwork as a full-bleed app background, veiled so
/// foreground text and controls stay legible in both light and dark mode —
/// the veil deepens toward the bottom, where the pinned action buttons live.
/// Falls back to the level-tint wash when the class has no art yet.
private struct ClassBackground: View {
    let focusClass: FocusClass
    let tint: Color

    var body: some View {
        if ClassArtwork.exists(for: focusClass) {
            Color.clear
                .overlay(
                    Image(focusClass.artworkName)
                        .resizable()
                        .scaledToFill()
                )
                .overlay(
                    LinearGradient(colors: [Color(.systemBackground).opacity(0.45),
                                            Color(.systemBackground).opacity(0.82)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .clipped()
                .ignoresSafeArea()
        } else {
            LevelBackground(tint: tint)
        }
    }
}

/// The level's color as an ambient wash: strongest at the top, fading toward
/// the system background so cards and text keep their contrast in both light
/// and dark mode. Derived from the level tint — no extra column in the
/// ladder table until levels get real background art.
private struct LevelBackground: View {
    let tint: Color

    var body: some View {
        LinearGradient(colors: [tint.opacity(0.30), tint.opacity(0.05)],
                       startPoint: .top, endPoint: .bottom)
            .background(Color(.systemBackground))
            .ignoresSafeArea()
    }
}

#Preview {
    let experience = ExperienceStore()
    let coins = CoinStore()
    let notifier = BlockNotifier()
    let workouts = WorkoutMonitor()
    let engine = FocusEngine(experience: experience, notifier: notifier)
    let chronicle = ChronicleStore(filename: nil)
    ContentView()
        .environmentObject(engine)
        .environmentObject(experience)
        .environmentObject(coins)
        .environmentObject(QuestBoard(engine: engine, coins: coins, workouts: workouts))
        .environmentObject(notifier)
        .environmentObject(workouts)
        .environmentObject(chronicle)
        .environmentObject(ClassStore(chronicle: chronicle, experience: experience))
}
