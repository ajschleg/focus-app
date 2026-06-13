import SwiftUI

/// The one full-screen moment the class system ever takes (CLASSES.md §9):
/// the day Wanderer ends. Every later shift is a quiet card on the plan
/// screen — this is the exception, shown exactly once.
struct FirstClassCeremonyView: View {
    let focusClass: FocusClass
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ClassArtwork(focusClass: focusClass, maxHeight: 240, placeholderDiameter: 132)

            Text("You've been seen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(focusClass.name)
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text(focusClass.whyLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    FirstClassCeremonyView(focusClass: ClassRoster.base[.mind]!, dismiss: {})
}
