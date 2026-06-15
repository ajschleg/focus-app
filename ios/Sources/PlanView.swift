import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var experience: ExperienceStore
    @EnvironmentObject private var coins: CoinStore
    @EnvironmentObject private var board: QuestBoard
    @EnvironmentObject private var notifier: BlockNotifier
    @EnvironmentObject private var classes: ClassStore

    /// The pre-focus quest being prompted (sheet) between tapping "Start
    /// focus" and the block actually starting.
    @State private var promptedQuest: Quest?
    /// Whether the ⓘ class-detail view (full art + description) is showing.
    @State private var showClassDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Plan a focus block")
                        .font(.largeTitle.bold())
                    Text("Pick a length, set the phone down, and work. We'll log when you leave the app or pick the phone up.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                LevelBadge(experience: experience, classes: classes) {
                    withAnimation(.easeInOut(duration: 0.3)) { showClassDetail = true }
                }

                if let shift = classes.shift {
                    PathShiftCard(from: shift.from, to: shift.to) { classes.shiftSeen() }
                }

                #if DEBUG
                DebugClassPicker(classes: classes)
                #endif

                HStack(spacing: 8) {
                    StatChip(text: "\(experience.total) XP", systemImage: "sparkles", tint: .secondary)
                    StatChip(text: "\(coins.balance)", systemImage: "f.circle.fill", tint: .orange)
                }

                VStack(spacing: 12) {
                    ForEach(BlockTemplate.presets) { template in
                        TemplateRow(template: template, selected: template == engine.template) {
                            engine.select(template)
                        }
                    }
                }

                if !board.menuQuests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quests")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(board.menuQuests) { quest in
                            MenuQuestRow(quest: quest,
                                         reportDone: { board.reportDone(quest) },
                                         accept: { board.accept(quest) })
                        }
                    }
                }

                if !engine.motionAvailable {
                    Label("Motion sensing is off here (likely the Simulator). Leave-the-app detection still works — run on a real iPhone to test pickups.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.orange)
                        .padding()
                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

                if let warning = notificationWarning {
                    VStack(spacing: 8) {
                        Label(warning, systemImage: "bell.slash.fill")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.orange)
                        Button("Open Settings") { notifier.openSettings() }
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

            }
            .padding()
        }
        // Pinned below the scroll: the primary action stays reachable no
        // matter how long the quest board gets. Content scrolls under the
        // material bar, which bleeds into the home-indicator area.
        .safeAreaInset(edge: .bottom) {
            Button {
                // A pre-focus quest intercepts the start — the block begins
                // from the prompt sheet (Done or skip), never silently.
                if let quest = board.preFocusQuest {
                    promptedQuest = quest
                } else {
                    engine.startFocus()
                }
            } label: {
                Text("Start focus · \(engine.template.focusMinutes) min")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .sheet(item: $promptedQuest) { quest in
            PreFocusQuestSheet(quest: quest) { completed in
                if completed { board.reportDone(quest) }
                promptedQuest = nil
                engine.startFocus()
            }
            .presentationDetents([.height(340)])
        }
        // The one full-screen moment the class system takes: the first
        // class ever (CLASSES.md §9). Later shifts are the quiet card above.
        .fullScreenCover(isPresented: Binding(
            get: { classes.ceremony != nil },
            set: { if !$0 { classes.ceremonySeen() } }
        )) {
            FirstClassCeremonyView(focusClass: classes.ceremony ?? classes.current) {
                classes.ceremonySeen()
            }
        }
        // Full-screen class detail: the background art revealed undimmed,
        // description in an opaque box at the bottom. Fades in over the plan
        // screen so it reads as the scrim lifting, not a new page.
        .overlay {
            if showClassDetail {
                ClassDetailView(classes: classes) {
                    withAnimation(.easeInOut(duration: 0.3)) { showClassDetail = false }
                }
                .transition(.opacity)
            }
        }
    }

    /// Why a locked phone would stay silent, if iOS would currently hide our
    /// phase-end alerts — permission off, or authorized but muted (Deliver
    /// Quietly / Lock Screen delivery unchecked).
    private var notificationWarning: String? {
        switch notifier.alertStatus {
        case .ok:
            return nil
        case .denied:
            return "Notifications are off, so a locked phone won't hear when a block or break ends."
        case .muted:
            return "Notifications are allowed but hidden — turn on Lock Screen and Banner alerts so a locked phone hears the end of a block."
        }
    }
}

/// The moment between tapping "Start focus" and the block beginning: one
/// healthy nudge, then focus starts either way — completing pays the bounty,
/// skipping just starts the block (the offer carries over to the next one).
/// Swiping the sheet away cancels the start entirely.
private struct PreFocusQuestSheet: View {
    @ObservedObject var quest: Quest
    /// Called with whether the quest was completed; the caller starts focus.
    let proceed: (_ completed: Bool) -> Void

    init(quest: Quest, proceed: @escaping (_ completed: Bool) -> Void) {
        self.quest = quest
        self.proceed = proceed
    }

    /// Themed quests (quest.tint) get their own scheme — Hydrate is water
    /// blue regardless of the current level; untinted ones follow the level.
    @ViewBuilder
    var body: some View {
        if let tint = quest.tint {
            content
                .tint(tint)
                .presentationBackground {
                    LinearGradient(colors: [tint.opacity(0.45), tint.opacity(0.10)],
                                   startPoint: .top, endPoint: .bottom)
                        .background(Color(.systemBackground))
                }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 96, height: 96)
                Image(systemName: quest.systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
            }
            .padding(.top, 24)
            Text(quest.title)
                .font(.title2.bold())
            Text(quest.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                proceed(true)
            } label: {
                Label("Done · +\(quest.reward)", systemImage: "f.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Skip — start the block") {
                proceed(false)
            }
            .font(.subheadline)
            .padding(.bottom, 8)
        }
        .padding()
    }
}

/// The current rung of the guild ladder: placeholder artwork in the level's
/// tint, the full title (rank + class), the target to beat, and live
/// promotion/demotion progress. The ⓘ answers "why this title?" with the
/// class's why-line plus receipts from the Chronicle.
private struct LevelBadge: View {
    @ObservedObject var experience: ExperienceStore
    @ObservedObject var classes: ClassStore
    /// Tapping the ⓘ — handled by the parent so the detail view can fill the
    /// whole screen (and reveal the background art) rather than a popover.
    let onInfo: () -> Void

    var body: some View {
        let level = experience.level
        VStack(spacing: 10) {
            // The ladder rank's emblem; the class itself is now the app
            // background (ClassBackground), so a portrait here would just
            // duplicate it. The title text below still names rank + class.
            ZStack {
                Circle()
                    .fill(level.tint.opacity(0.15))
                    .frame(width: 84, height: 84)
                Image(systemName: level.systemImage)
                    .font(.system(size: 36))
                    .foregroundStyle(level.tint)
            }
            HStack(spacing: 6) {
                Text("Level \(experience.levelNumber) · \(level.name) \(classes.current.name)")
                    .font(.headline)
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(progressLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if experience.misses > 0, let previous = experience.previousLevel {
                Text("\(experience.misses)/\(level.missesToDemote) slips below target — drop to \(previous.name)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(level.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var progressLine: String {
        let level = experience.level
        guard let next = experience.nextLevel else {
            return "The top of the guild. Score \(level.targetScore)+ to hold the title."
        }
        return "Score \(level.targetScore)+ in a block · \(experience.wins)/\(level.winsToPromote) toward \(next.name)"
    }
}

/// Tapping the ⓘ lifts the background scrim: the class art fills the screen
/// undimmed, with the "why this title" copy in an opaque box pinned to the
/// bottom. Tap the art (or the ✕) to dismiss. Receipts are generated from
/// the Chronicle — personal evidence, not canned copy; the *level* half of
/// the title is still open (CLASSES.md §10), so this speaks only for the
/// class.
private struct ClassDetailView: View {
    @ObservedObject var classes: ClassStore
    let dismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full art, undimmed; tap anywhere on it to dismiss. The info
            // animation plays here when present (ART.md §7) — else the still.
            Group {
                if !reduceMotion, let clip = ClassMotionLoader.url(classes.current.name, .info) {
                    LoopingVideoView(url: clip)
                } else if let art = ClassImageLoader.image(classes.current.artworkName, maxDimension: 2000) {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemBackground)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { dismiss() }

            // The description, in a fully opaque box at the bottom.
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Label(classes.current.name, systemImage: classes.current.systemImage)
                        .font(.title2.bold())
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Text(classes.current.whyLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !classes.receipts.isEmpty {
                    Text("Driven by " + classes.receipts.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if classes.isQuiet {
                    Text("Your Chronicle has been quiet lately — this title holds until new evidence arrives.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }
}

/// The quiet drift announcement (CLASSES.md §9): no modal, no fanfare —
/// a dismissible row that waits on the plan screen.
private struct PathShiftCard: View {
    let from: String
    let to: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your path has shifted")
                    .font(.subheadline.weight(.semibold))
                Text("\(from) → \(to)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
/// Debug-only roster switcher: force the displayed class to any of the 30
/// so the background and title can be checked without grinding real
/// Chronicle data. Stripped from release builds. Classes without artwork
/// yet fall back to the level-tint wash, which is itself worth seeing.
private struct DebugClassPicker: View {
    @ObservedObject var classes: ClassStore

    var body: some View {
        Menu {
            Button {
                classes.debugClear()
            } label: {
                Label("Live (real class)", systemImage: "bolt.fill")
            }
            Divider()
            ForEach(ClassRoster.debugAll, id: \.name) { focusClass in
                Button(focusClass.name) { classes.debugSet(focusClass) }
            }
        } label: {
            Label(classes.debugSelection.map { "Debug: \($0.name)" } ?? "Debug: pick class",
                  systemImage: "testtube.2")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: Capsule())
        }
    }
}
#endif

/// A small capsule for the header totals (XP, focus coins).
private struct StatChip: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary, in: Capsule())
    }
}

/// One offer on the quest board. Self-reported quests get a "Done" button;
/// auto-judged challenges get an "Accept" button — they only apply to a block
/// taken on deliberately, and show as accepted once armed. Observes the quest
/// directly so taps update the row.
private struct MenuQuestRow: View {
    @ObservedObject var quest: Quest
    let reportDone: () -> Void
    let accept: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quest.systemImage)
                .font(.title3)
                // .tint (not Color.accentColor) so the level's color scheme applies
                .foregroundStyle(quest.status == .completed ? AnyShapeStyle(.green) : AnyShapeStyle(.tint))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title).font(.subheadline.weight(.semibold))
                Text(quest.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            trailing
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var trailing: some View {
        switch quest.status {
        case .completed:
            Label("+\(quest.reward)", systemImage: "f.circle.fill")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.green)
        case .offered where quest.isSelfReported:
            Button("Done", action: reportDone)
                .buttonStyle(.bordered)
                .controlSize(.small)
        case .offered where quest.isAutomatic:
            // Nothing to tap — an outside signal (Health) completes these.
            VStack(alignment: .trailing, spacing: 6) {
                bounty
                Label("Auto", systemImage: "heart.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        case .offered:
            VStack(alignment: .trailing, spacing: 6) {
                bounty
                Button("Accept", action: accept)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        case .active:
            VStack(alignment: .trailing, spacing: 6) {
                bounty
                Label("Accepted", systemImage: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        case .failed:
            EmptyView()   // resolved rows are swept before planning shows them
        }
    }

    private var bounty: some View {
        Label("\(quest.reward)", systemImage: "f.circle.fill")
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .foregroundStyle(.orange)
    }
}

private struct TemplateRow: View {
    let template: BlockTemplate
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name).font(.headline)
                    Text("\(template.focusMinutes) min focus · \(template.breakMinutes) min break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    // .tint (not Color.accentColor) so the level's color scheme applies
                    .foregroundStyle(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let experience = ExperienceStore()
    let coins = CoinStore()
    let notifier = BlockNotifier()
    let workouts = WorkoutMonitor()
    let engine = FocusEngine(experience: experience, notifier: notifier)
    let chronicle = ChronicleStore(filename: nil)
    PlanView()
        .environmentObject(engine)
        .environmentObject(experience)
        .environmentObject(coins)
        .environmentObject(QuestBoard(engine: engine, coins: coins, workouts: workouts))
        .environmentObject(notifier)
        .environmentObject(workouts)
        .environmentObject(chronicle)
        .environmentObject(ClassStore(chronicle: chronicle, experience: experience))
}
