import SwiftUI

// Action buttons sit over the class-art background (ART.md §7), which is busy
// and sometimes animated (the focus/info clips). The system's translucent
// `.bordered` fill washes out there, so these give buttons a solid surface and
// a soft shadow to lift them off the backdrop. Label colors are left to the
// tint/role so they stay legible on any level tint — the ladder runs from mint
// and yellow to red, so a fill can't assume a light or dark label.

extension View {
    /// Soft drop shadow that separates a control from the busy class-art
    /// backdrop. Applied to the already-opaque `.borderedProminent` buttons
    /// (and baked into `.solidBordered`).
    func liftedOverBackground() -> some View {
        shadow(color: .black.opacity(0.22), radius: 7, y: 2)
    }
}

/// A secondary action button that stays readable over the background: an
/// opaque material fill (vs. the system `.bordered` translucency) with the
/// label in the tint, or red for a destructive role. Honors `controlSize` so
/// inline `.small` buttons stay compact.
struct SolidBorderedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: Configuration) -> some View {
        let small = controlSize == .mini || controlSize == .small
        let shape = RoundedRectangle(cornerRadius: small ? 8 : 12, style: .continuous)
        let label: AnyShapeStyle = configuration.role == .destructive
            ? AnyShapeStyle(.red) : AnyShapeStyle(.tint)

        return configuration.label
            .fontWeight(.medium)
            .foregroundStyle(label)
            .padding(.vertical, small ? 5 : 10)
            .padding(.horizontal, small ? 12 : 16)
            .background(.thickMaterial, in: shape)
            .overlay(shape.strokeBorder(.primary.opacity(0.08)))
            .liftedOverBackground()
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SolidBorderedButtonStyle {
    /// Secondary action that reads over the class-art background — opaque fill
    /// + lift, in place of the translucent system `.bordered`.
    static var solidBordered: SolidBorderedButtonStyle { SolidBorderedButtonStyle() }
}

extension View {
    /// Opaque card/chip background for the plan-screen menu (template rows,
    /// stat chips, quest rows). The system `.quaternary` fill is too faint to
    /// read over the class-art backdrop, so this uses a frosted material with a
    /// hairline edge. `selected` washes it in the tint and thickens the ring,
    /// so the chosen row is unmistakable.
    func menuSurface<S: InsettableShape>(_ shape: S, selected: Bool = false) -> some View {
        background {
            shape.fill(.regularMaterial)
            if selected { shape.fill(.tint.opacity(0.22)) }
        }
        .overlay {
            shape.strokeBorder(
                selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary.opacity(0.10)),
                lineWidth: selected ? 2 : 0.5
            )
        }
    }
}
