import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var engine: FocusEngine

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Focusing")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(timeString(engine.remaining))
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            HStack(spacing: 40) {
                LiveStat(count: engine.leftAppCount, label: "left app", systemImage: "arrow.up.forward.app")
                LiveStat(count: engine.pickupCount, label: "pickups", systemImage: "iphone")
            }

            Text("Phone down. When you leave the app or pick it up, it shows up here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 8) {
                Button(role: .destructive) {
                    engine.endBlock()
                } label: {
                    Text("End block early")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if engine.potentialEarlyQuitPenalty > 0 {
                    Text("Quitting now costs \(engine.potentialEarlyQuitPenalty) pts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding()
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct LiveStat: View {
    let count: Int
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.title2)
            Text("\(count)")
                .font(.system(.largeTitle, design: .rounded).bold())
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(minWidth: 100)
    }
}

#Preview {
    FocusView().environmentObject(FocusEngine())
}
