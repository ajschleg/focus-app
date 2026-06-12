import SwiftUI

/// The break recap (CLASSES.md §7): its own feather-light moment between a
/// taken break and the review. Bubbles, Continue, Skip — by design it never
/// grows questions, text fields, or a second step, because it stands
/// between the player and their score. No coins (pillar 5): taps only feed
/// the Chronicle, so there's nothing to lie for.
struct BreakRecapView: View {
    @EnvironmentObject private var chronicle: ChronicleStore
    @Environment(\.dismiss) private var dismiss

    @State private var shelf: [ActivityKind] = []
    @State private var selected: [ActivityKind] = []
    @State private var expanded = false

    private let maxPicks = 3

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("What did you get up to?")
                    .font(.title3.bold())
                Text("Off the record — no coins, just your story. Pick up to \(maxPicks).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            bubbles(for: expanded ? ActivityKind.recapBubbles : shelf)

            if !expanded {
                Button("More…") { expanded = true }
                    .font(.footnote)
            }

            Spacer()

            VStack(spacing: 8) {
                Button {
                    selected.forEach { chronicle.record($0) }
                    dismiss()
                } label: {
                    Text(selected.isEmpty ? "Continue" : "Continue · \(selected.count) noted")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip") { dismiss() }
                    .font(.subheadline)
            }
            .padding(.bottom, 8)
        }
        .padding()
        .onAppear {
            shelf = ClassEngine.recapShelf(entries: chronicle.entries, asOf: Date())
        }
    }

    @ViewBuilder
    private func bubbles(for kinds: [ActivityKind]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(kinds, id: \.self) { kind in
                    bubble(kind)
                }
            }
        }
    }

    private func bubble(_ kind: ActivityKind) -> some View {
        let isOn = selected.contains(kind)
        return Button {
            if isOn {
                selected.removeAll { $0 == kind }
            } else if selected.count < maxPicks {
                selected.append(kind)
            }
        } label: {
            Text(kind.info.label)
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isOn ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.quaternary),
                            in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BreakRecapView()
        .environmentObject(ChronicleStore(filename: nil))
}
