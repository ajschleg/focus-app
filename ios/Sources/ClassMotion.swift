import Foundation

/// The moments a class animation can play (ART.md §7). Raw values are the
/// folder name under a class: `ClassMotion/<Class>/<moment>/`.
enum ClassMotionMoment: String {
    case info       // full-screen behind the ⓘ class detail
    case focus      // scrimmed, behind a running focus block
    case ceremony   // the first-class award
    case levelUp = "levelup"
}

/// Resolves bundled class-animation clips (ART.md §7). Clips are organized
/// per class then per moment — `ClassMotion/<Class>/<moment>/<anything>.mov`
/// — bundled as a folder reference so the structure is preserved. The first
/// clip found in the matching folder wins (any filename, `.mov` or `.mp4`),
/// so dropping a file into the right folder is all it takes. No clip → the
/// caller shows the static art.
enum ClassMotionLoader {
    static func url(_ className: String, _ moment: ClassMotionMoment) -> URL? {
        let dir = "ClassMotion/\(className)/\(moment.rawValue)"
        for ext in ["mov", "mp4"] {
            if let url = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: dir)?
                .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first {
                return url
            }
        }
        return nil
    }
}
