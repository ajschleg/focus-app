import Foundation

/// The focus-coin purse — the earned currency from CONCEPT.md §5A. Coins come
/// from completing quests (`QuestBoard` pays out) and persist as a lifetime
/// balance, separate from XP: XP is the permanent progress ledger, coins are
/// the spendable kind. Spending them (the break free-track, §6) comes later.
final class CoinStore: ObservableObject {
    @Published private(set) var balance: Int

    private static let balanceKey = "coins.balance"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        balance = defaults.integer(forKey: Self.balanceKey)
    }

    func earn(_ amount: Int) {
        guard amount > 0 else { return }
        balance += amount
        defaults.set(balance, forKey: Self.balanceKey)
    }
}
