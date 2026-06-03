import SwiftUI

/// Routes between the three states of the core loop and wires up the
/// leave-the-app signal via `scenePhase`.
struct ContentView: View {
    @EnvironmentObject private var engine: FocusEngine
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch engine.state {
            case .planning: PlanView()
            case .focusing: FocusView()
            case .review:   ReviewView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Going to .background while focusing is the strong "I got
            // distracted / left the app" signal (no entitlement needed).
            if newPhase == .background, engine.state == .focusing {
                engine.sceneWentToBackground()
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(FocusEngine())
}
