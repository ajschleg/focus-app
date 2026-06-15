import SwiftUI

/// Renders a class's artwork when a matching asset exists in the `ClassArt`
/// catalog, else the placeholder SF symbol. Testing a new figure (or a new
/// style for an existing one) is just dropping a PNG named for the class
/// into Assets.xcassets/ClassArt — the app picks it up with no code change
/// (pillar 6). Images fit within `maxHeight` at their own aspect, so
/// portrait or square test art both display whole.
struct ClassArtwork: View {
    let focusClass: FocusClass
    var maxHeight: CGFloat = 160
    var placeholderDiameter: CGFloat = 84

    /// Whether real art is present (vs. the SF-symbol placeholder) — lets
    /// callers reshape layout around a portrait.
    static func exists(for focusClass: FocusClass) -> Bool {
        ClassImageLoader.exists(focusClass.artworkName)
    }

    var body: some View {
        // Thumbnail-sized: badge ~200pt, ceremony ~240pt → 700px covers 3×.
        if let art = ClassImageLoader.image(focusClass.artworkName, maxDimension: 700) {
            Image(uiImage: art)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: maxHeight)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: placeholderDiameter, height: placeholderDiameter)
                Image(systemName: focusClass.systemImage)
                    .font(.system(size: placeholderDiameter * 0.42))
                    .foregroundStyle(.tint)
            }
        }
    }
}
