import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var experience: ExperienceStore
    @EnvironmentObject private var board: QuestBoard

    /// The break recap (CLASSES.md §7): its own moment between a *taken*
    /// break and the review — presented the instant review appears, only
    /// when a real break happened. Swiping it away is the Skip.
    @State private var showRecap = false

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

                VStack(spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(engine.score)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor)
                        Text("/ 100")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    // The score was banked as XP on entering review, so the
                    // total shown here already includes this block.
                    Label("+\(engine.score) XP · \(experience.total) total", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if let outcome = experience.lastOutcome {
                    LevelVerdict(outcome: outcome, experience: experience)
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

                BreakSummary(detail: breakDetail, credit: engine.breakCredit)

                if !board.resolvedQuests.isEmpty {
                    QuestOutcomes(quests: board.resolvedQuests,
                                  coinsEarned: board.coinsEarnedThisCycle)
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

            }
            .padding()
        }
        // Pinned below the scroll, same as the plan screen's start button —
        // however long the review gets, the way forward is always on screen.
        .safeAreaInset(edge: .bottom) {
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
            .liftedOverBackground()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .onAppear { showRecap = engine.completedBreak > 0 }
        .sheet(isPresented: $showRecap) {
            BreakRecapView()
                .presentationDetents([.medium, .large])
        }
    }

    private var remainingAtQuit: TimeInterval {
        max(0, engine.template.focusDuration - engine.completedFocus)
    }

    /// One-line account of the break that feeds the `BreakSummary` banner.
    private var breakDetail: String {
        guard engine.breakDuration > 0 else { return "Ended focus too early to earn a break" }
        guard engine.completedBreak > 0 else { return "Break skipped" } // declined at the prompt
        let taken = minutesString(engine.completedBreak)
        if engine.breakEndedEarly { return "\(taken) taken · break skipped early" }
        if engine.endedEarly { return "\(taken) taken · shortened from \(minutesString(engine.template.breakDuration))" }
        return "\(taken) taken · full break"
    }

    /// Colored against the *ladder's* bar, not fixed bands — the big number
    /// and the verdict card directly beneath it must never disagree.
    private var scoreColor: Color {
        let target = experience.lastOutcome?.target ?? experience.level.targetScore
        if engine.score >= target { return .green }
        if engine.score >= target - 10 { return .yellow }
        return .orange
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

/// The ladder's verdict on this block: promoted (with the coin reward, or a
/// note that it was already claimed), demoted, or progress toward either.
/// `experience` reflects the level *after* the move, which is what we show.
private struct LevelVerdict: View {
    let outcome: LevelOutcome
    @ObservedObject var experience: ExperienceStore

    var body: some View {
        let level = experience.level
        HStack(spacing: 12) {
            Image(systemName: level.systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if case .promoted(let coins) = outcome.movement, coins > 0 {
                Label("+\(coins)", systemImage: "f.circle.fill")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var tint: Color {
        switch outcome.movement {
        case .promoted: return experience.level.tint
        case .demoted:  return .orange
        case .stayed:   return outcome.metTarget ? .green : .orange
        }
    }

    private var headline: String {
        switch outcome.movement {
        case .promoted: return "Promoted to \(experience.level.name)!"
        case .demoted:  return "Demoted to \(experience.level.name)"
        case .stayed:   return outcome.metTarget ? "Target met — \(outcome.score) vs \(outcome.target)"
                                                 : "Below target — \(outcome.score) vs \(outcome.target)"
        }
    }

    private var detail: String {
        let level = experience.level
        switch outcome.movement {
        case .promoted(let coins):
            return coins > 0 ? "First time at this level — reward earned."
                             : "Reward already claimed for this level."
        case .demoted:
            return "Score \(level.targetScore)+ to climb back."
        case .stayed:
            if outcome.metTarget {
                guard let next = experience.nextLevel else { return "Holding the title." }
                return "\(experience.wins)/\(level.winsToPromote) wins toward \(next.name)"
            } else {
                guard let previous = experience.previousLevel else { return "No demotion at level 1 — keep climbing." }
                return "\(experience.misses)/\(level.missesToDemote) slips before dropping to \(previous.name)"
            }
        }
    }
}

/// How the cycle's quests settled and the focus coins they paid out. Statuses
/// are final by the time review renders, so plain reads are enough here.
private struct QuestOutcomes: View {
    let quests: [Quest]
    let coinsEarned: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Quests")
                    .font(.headline)
                Spacer()
                if coinsEarned > 0 {
                    Label("+\(coinsEarned)", systemImage: "f.circle.fill")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.orange)
                }
            }
            .padding(.bottom, 8)
            ForEach(quests) { quest in
                HStack {
                    Image(systemName: quest.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .frame(width: 24)
                        .foregroundStyle(quest.status == .completed ? .green : .orange)
                    Text(quest.title)
                    Spacer()
                    Text(quest.status == .completed ? "+\(quest.reward)" : "—")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(quest.status == .completed ? .green : .secondary)
                }
                .padding(.vertical, 8)
                if quest.id != quests.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// The break payoff: how much break you took and the credit it folded into the
/// score. Always shown — a full break is a positive to reinforce (CONCEPT.md §5).
private struct BreakSummary: View {
    let detail: String
    let credit: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Break")
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("+\(credit)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(credit > 0 ? .green : .secondary)
        }
        .padding()
        .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let experience = ExperienceStore()
    let engine = FocusEngine(experience: experience)
    ReviewView()
        .environmentObject(engine)
        .environmentObject(experience)
        .environmentObject(QuestBoard(engine: engine, coins: CoinStore(), workouts: WorkoutMonitor()))
        .environmentObject(ChronicleStore(filename: nil))
}
