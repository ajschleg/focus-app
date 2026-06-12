import SwiftUI

/// The moment after focus ends: the break is on offer, not running. Taking it
/// is the default, visually prominent path (CONCEPT.md §5: reward proper
/// breaks); skipping is allowed but shows exactly what it forfeits.
struct BreakPromptView: View {
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var board: QuestBoard

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

            if let quest = board.exerciseQuest {
                WalkNudgeCard(quest: quest)
            }

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

/// The exercise quest's moment: a break is a ready-made chance to knock it
/// out. Purely a pointer — the quest completes on its own when a workout
/// syncs in from Health, so the card observes the quest and flips to a
/// confirmation if that happens while this screen is up.
private struct WalkNudgeCard: View {
    @ObservedObject var quest: Quest

    private var done: Bool { quest.status == .completed }
    private var tint: Color { quest.tint ?? .green }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : quest.systemImage)
                .font(.title2)
                .foregroundStyle(done ? .green : tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(done ? "Workout logged" : "No workout yet today")
                    .font(.headline)
                Text(done ? "\"\(quest.title)\" is done — coins paid."
                          : "Take this break as a short walk. Log it as a workout and \"\(quest.title)\" completes on its own.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label("\(done ? "+" : "")\(quest.reward)", systemImage: "f.circle.fill")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(done ? .green : .orange)
        }
        .padding()
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    let engine = FocusEngine()
    BreakPromptView()
        .environmentObject(engine)
        .environmentObject(QuestBoard(engine: engine, coins: CoinStore(), workouts: WorkoutMonitor()))
}
