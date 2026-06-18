import SwiftUI

/// The break phase, auto-started right after focus. Calm by design — it nudges
/// you *off* the screen (CONCEPT.md §6) while the break credit climbs as you
/// actually rest. Ending focus early shortens this break, which is called out
/// here so the shorter timer isn't a mystery.
struct BreakView: View {
    @EnvironmentObject private var engine: FocusEngine

    private var wasShortened: Bool {
        engine.endedEarly && engine.breakDuration < engine.template.breakDuration
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Break")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(timeString(engine.remaining))
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.green)

            VStack(spacing: 2) {
                Text("+\(engine.breakCredit)")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(.green)
                Text("break credit").font(.caption).foregroundStyle(.secondary)
            }

            if wasShortened {
                Text("Break shortened to \(minutesString(engine.breakDuration)) because you ended focus early.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Step away from the screen — stretch, breathe, look out a window. Finish the break to keep the credit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                engine.endBreak()
            } label: {
                Text("Skip break")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.solidBordered)
            .controlSize(.large)
        }
        .padding()
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func minutesString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}

#Preview {
    BreakView().environmentObject(FocusEngine())
}
