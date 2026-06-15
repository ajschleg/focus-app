import SwiftUI
import UIKit

/// Loads class artwork **downsampled** to an on-screen size and caches the
/// result, so a full-screen background never keeps a ~20 MB full-resolution
/// bitmap resident for rendering. A 1792×2688 source decodes to ~19 MB no
/// matter how small the PNG is on disk; rendering that full-bleed (and
/// re-compositing it on every state change) is what pushed the app over the
/// memory limit on device.
///
/// Source art should still be exported small (see ART.md — ~1290–1600 px on
/// the long edge is plenty for a phone), but this caps memory even if a
/// large one slips in. The `NSCache` evicts under memory pressure.
enum ClassImageLoader {
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 8   // a handful of recently shown classes
        return c
    }()

    static func exists(_ artworkName: String) -> Bool {
        UIImage(named: artworkName) != nil
    }

    /// Downsampled image for `artworkName`, longest edge ≤ `maxDimension`
    /// points; nil when the class has no art. Cached per (name, size).
    static func image(_ artworkName: String, maxDimension: CGFloat) -> UIImage? {
        let key = "\(artworkName)#\(Int(maxDimension))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let source = UIImage(named: artworkName) else { return nil }

        let longest = max(source.size.width, source.size.height)
        let result: UIImage
        if longest <= maxDimension {
            result = source
        } else {
            let ratio = maxDimension / longest
            let size = CGSize(width: (source.size.width * ratio).rounded(),
                              height: (source.size.height * ratio).rounded())
            result = source.preparingThumbnail(of: size) ?? source
        }
        cache.setObject(result, forKey: key)
        return result
    }
}
