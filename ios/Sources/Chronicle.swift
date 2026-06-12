import Foundation
import Combine

/// One observed fact: an activity kind and when it happened.
struct ChronicleEntry: Codable, Equatable {
    let kind: ActivityKind
    let date: Date
}

/// The append-only history everything class-shaped is computed from
/// (CLASSES.md §4): finished blocks, quest completions, break-recap taps.
/// Local JSON, never pruned — entries are a kind and a date, so a decade
/// costs kilobytes, and the year recap depends on the full history.
///
/// Like `QuestBoard`, it observes the engine (and the board's quests) from
/// the outside; nothing here touches block logic. The bare initializer is
/// for tests and previews.
final class ChronicleStore: ObservableObject {
    @Published private(set) var entries: [ChronicleEntry] = []

    private let url: URL?
    private var subs = Set<AnyCancellable>()
    /// One completion watcher per adopted quest, mirroring the board's
    /// payout subscriptions.
    private var questSubs = [UUID: AnyCancellable]()

    /// On-disk store. Pass `filename: nil` for an in-memory store (tests).
    init(filename: String? = "chronicle.json") {
        if let filename {
            let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask)[0]
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            url = dir.appendingPathComponent(filename)
        } else {
            url = nil
        }
        load()
    }

    /// Wire up the automatic signals: every reviewed block is a Mind mark,
    /// and every quest completion logs its activity kind.
    func observe(engine: FocusEngine, board: QuestBoard) {
        engine.$state
            .removeDuplicates()
            .sink { [weak self] state in
                if state == .review { self?.record(.focusBlock) }
            }
            .store(in: &subs)

        board.$quests
            .sink { [weak self] quests in self?.watch(quests) }
            .store(in: &subs)
    }

    func record(_ kind: ActivityKind, at date: Date = Date()) {
        entries.append(ChronicleEntry(kind: kind, date: date))
        save()
    }

    // MARK: - Private

    private func watch(_ quests: [Quest]) {
        for quest in quests {
            guard questSubs[quest.id] == nil, let kind = quest.activity else { continue }
            questSubs[quest.id] = quest.$status
                .first { $0 == .completed }
                .sink { [weak self] _ in self?.record(kind) }
        }
        let alive = Set(quests.map(\.id))
        questSubs = questSubs.filter { alive.contains($0.key) }
    }

    private func load() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        entries = (try? decoder.decode([ChronicleEntry].self, from: data)) ?? []
    }

    private func save() {
        guard let url else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
