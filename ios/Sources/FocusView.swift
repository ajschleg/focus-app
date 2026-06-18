import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var board: QuestBoard

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

            if let quest = board.focusQuest {
                SurpriseQuestBanner(quest: quest)
                    .padding(.horizontal)
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
                .buttonStyle(.solidBordered)
                .controlSize(.large)

                if engine.potentialEarlyQuitPenalty > 0 {
                    VStack(spacing: 2) {
                        Text("Quitting now costs \(engine.potentialEarlyQuitPenalty) pts")
                        Text("and shortens your break to \(timeString(engine.potentialBreakLength))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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

/// The mid-block surprise quest, glanceable only — completing it requires
/// *not* touching the phone, so there is deliberately nothing to tap here.
/// Observes the quest for the live countdown and the resolve flip.
private struct SurpriseQuestBanner: View {
    @ObservedObject var quest: Quest

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quest.systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Quest: \(quest.title)")
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trailing
        }
        .padding()
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var tint: Color {
        switch quest.status {
        case .completed: return .green
        case .failed:    return .orange
        default:         return .purple
        }
    }

    private var subtitle: String {
        switch quest.status {
        case .completed: return "Held it — coins banked."
        case .failed:    return "Blown — next time."
        default:         return quest.detail
        }
    }

    @ViewBuilder private var trailing: some View {
        switch quest.status {
        case .completed:
            Label("+\(quest.reward)", systemImage: "f.circle.fill")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
        default:
            VStack(spacing: 2) {
                if let stillness = quest as? StillnessQuest {
                    Text(countdownString(stillness.secondsLeft))
                        .font(.title3.bold().monospacedDigit())
                        .contentTransition(.numericText())
                }
                Label("\(quest.reward)", systemImage: "f.circle.fill")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.orange)
            }
        }
    }

    private func countdownString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
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
    let engine = FocusEngine()
    FocusView()
        .environmentObject(engine)
        .environmentObject(QuestBoard(engine: engine, coins: CoinStore(), workouts: WorkoutMonitor()))
}
