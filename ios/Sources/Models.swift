import Foundation

/// A focus/break template, e.g. 50 minutes focus / 10 minutes break.
///
/// The "Quick test" preset exists so you can exercise the whole loop in a
/// minute instead of waiting out a real block while tuning detection.
struct BlockTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let focusMinutes: Int
    let breakMinutes: Int

    /// Focus length in seconds.
    var focusDuration: TimeInterval { TimeInterval(focusMinutes * 60) }

    static let presets: [BlockTemplate] = [
        BlockTemplate(name: "Quick test", focusMinutes: 1, breakMinutes: 1),
        BlockTemplate(name: "Pomodoro", focusMinutes: 25, breakMinutes: 5),
        BlockTemplate(name: "Classic", focusMinutes: 50, breakMinutes: 10),
        BlockTemplate(name: "Deep work", focusMinutes: 90, breakMinutes: 20),
    ]
}

/// The kinds of distraction we can actually detect within Apple's privacy
/// limits (see CONCEPT.md §3). This is a fusion of signals, not a timeline.
enum DistractionKind: String {
    case leftApp   // scenePhase went to .background while focusing
    case pickup    // CoreMotion: the phone was picked up / moved significantly

    var label: String {
        switch self {
        case .leftApp: return "Left the app"
        case .pickup:  return "Picked up the phone"
        }
    }

    var systemImage: String {
        switch self {
        case .leftApp: return "arrow.up.forward.app"
        case .pickup:  return "iphone"
        }
    }
}

/// A single detected distraction during a focus block.
struct DistractionEvent: Identifiable {
    let id = UUID()
    let kind: DistractionKind
    let date: Date
    /// Seconds since the block started — gives the log a rough timeline.
    let offset: TimeInterval
}

/// High-level state of the slice's core loop.
enum SessionState {
    case planning
    case focusing
    case review
}
