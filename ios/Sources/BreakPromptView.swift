import SwiftUI

/// The moment after focus ends: the break is on offer, not running. Taking it
/// is the default, visually prominent path (CONCEPT.md §5: reward proper
/// breaks); skipping is allowed but shows exactly what it forfeits.
struct BreakPromptView: View {
    @EnvironmentObject private var engine: FocusEngine

    private var wasShortened: Bool {
        engine.endedEarly && engine.breakDuration < engine.template.breakDuration
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 6) {
                Text(engine.endedEarly ? "Block ended early" : "Block complete")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("You've earned a break")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                Text(timeString(engine.breakDuration))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.green)
                Text("break on offer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if wasShortened {
                Text("Shortened from \(timeString(engine.template.breakDuration)) because you ended focus early.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("Step away from the screen — stretch, walk, look out a window. Taking the full break adds +\(engine.potentialBreakCredit) to this block's score.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 8) {
                Button {
                    engine.takeBreak()
                } label: {
                    Text("Start break")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)

                Button {
                    engine.skipBreak()
                } label: {
                    Text("Skip break · forfeit +\(engine.potentialBreakCredit)")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#Preview {
    BreakPromptView().environmentObject(FocusEngine())
}
