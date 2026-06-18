import Foundation

/// The moments a class animation can play (ART.md §7). Raw values are the
/// folder name under a class: `ClassMotion/<Class>/<moment>/`.
enum ClassMotionMoment: String {
    case info       // full-screen behind the ⓘ class detail
    case focus      // scrimmed, behind a running focus block
    case ceremony   // the first-class award
    case levelUp = "levelup"

    /// When a moment's own folder has no clip, reuse this moment's instead, so
    /// one bundled file can cover several moments (less app space). `focus` is
    /// the same source visual as `info` — just scrimmed at the view layer — so
    /// it reuses the `info` clip unless a distinct `focus/` clip is provided.
    var reuses: ClassMotionMoment? {
        switch self {
        case .focus: return .info
        default:     return nil
        }
    }
}

/// Resolves bundled class-animation clips (ART.md §7). Clips are organized
/// per class then per moment — `ClassMotion/<Class>/<moment>/<anything>.mov`
/// — bundled as a folder reference so the structure is preserved. The first
/// clip found in the matching folder wins (any filename, `.mov` or `.mp4`),
/// so dropping a file into the right folder is all it takes. A moment with no
/// clip of its own falls back to the clip it `reuses` (`focus` → `info`), so
/// one file can serve both. Nothing to fall back to → the caller shows the
/// static art.
enum ClassMotionLoader {
    static func url(_ className: String, _ moment: ClassMotionMoment) -> URL? {
        var moment: ClassMotionMoment? = moment
        while let m = moment {
            let dir = "ClassMotion/\(className)/\(m.rawValue)"
            for ext in ["mov", "mp4"] {
                if let url = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: dir)?
                    .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first {
                    return url
                }
            }
            moment = m.reuses   // fall back to the shared clip, if any
        }
        return nil
    }
}
