import SwiftUI

@main
struct FocusSliceApp: App {
    @StateObject private var engine = FocusEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
        }
    }
}
