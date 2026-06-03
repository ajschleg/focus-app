import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var engine: FocusEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(engine.endedEarly ? "Block ended early" : "Block complete")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(engine.template.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(engine.score)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Text("/ 100")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    SummaryCard(value: minutesString(engine.completedFocus), label: "focused")
                    SummaryCard(value: "\(engine.leftAppCount)", label: "left app")
                    SummaryCard(value: "\(engine.pickupCount)", label: "pickups")
                }

                if engine.endedEarly {
                    EarlyQuitBanner(remainingText: minutesString(remainingAtQuit),
                                    penalty: engine.earlyQuitPenalty)
                }

                if engine.events.isEmpty {
                    if !engine.endedEarly {
                        Label("No distractions detected — clean block!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .padding(.vertical, 8)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Distraction log")
                            .font(.headline)
                            .padding(.bottom, 8)
                        ForEach(engine.events) { event in
                            HStack {
                                Image(systemName: event.kind.systemImage)
                                    .frame(width: 24)
                                    .foregroundStyle(.secondary)
                                Text(event.kind.label)
                                Spacer()
                                Text("@ \(offsetString(event.offset))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            if event.id != engine.events.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    engine.reset()
                } label: {
                    Text("Plan another block")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private var remainingAtQuit: TimeInterval {
        max(0, engine.template.focusDuration - engine.completedFocus)
    }

    private var scoreColor: Color {
        switch engine.score {
        case 85...:    return .green
        case 60..<85:  return .yellow
        default:       return .orange
        }
    }

    private func minutesString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func offsetString(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct SummaryCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct EarlyQuitBanner: View {
    let remainingText: String
    let penalty: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hourglass.bottomhalf.filled")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ended early")
                    .font(.headline)
                Text("\(remainingText) left on the clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if penalty > 0 {
                Text("−\(penalty)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.orange)
            } else {
                Text("no penalty")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ReviewView().environmentObject(FocusEngine())
}
