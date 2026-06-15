import Foundation

/// The moments a class animation can play (ART.md §7). Raw values are the
/// filename suffix: `<ClassName>-<moment>.mov`.
enum ClassMotionMoment: String {
    case info       // full-screen behind the ⓘ class detail
    case focus      // scrimmed, behind a running focus block
    case ceremony   // the first-class award
    case levelUp = "levelup"
}

/// Resolves bundled class-animation clips (ART.md §7). Clips live in
/// Resources/ClassMotion as `<ClassName>-<moment>.mov` (or `.mp4`). A
/// moment-specific clip wins; otherwise a class's bare `<ClassName>` clip is
/// the ambient fallback; otherwise nil, and the caller shows the static art.
enum ClassMotionLoader {
    static func url(_ className: String, _ moment: ClassMotionMoment) -> URL? {
        clip("\(className)-\(moment.rawValue)") ?? clip(className)
    }

    private static func clip(_ name: String) -> URL? {
        for ext in ["mov", "mp4"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}
