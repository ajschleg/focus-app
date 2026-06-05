import Foundation

/// How one reviewed block moved the player on the monk's ladder — built by
/// `ExperienceStore.recordBlock`, read by the review screen.
struct LevelOutcome {
    enum Movement: Equatable {
        case stayed
        /// Coins are 0 on a repeat promotion (level was reached before — the
        /// reward can't be farmed by bouncing up and down).
        case promoted(coinsAwarded: Int)
        case demoted
    }

    let score: Int
    /// The target that was in force when the block was judged.
    let target: Int
    let metTarget: Bool
    let movement: Movement
}

/// The experience system: a lifetime XP total plus the league-style level
/// ladder (CONCEPT.md §5D). Each block banks its final 0–100 score as XP and
/// gets judged against the current level's target — wins climb toward
/// promotion, misses sink toward demotion (see `FocusLevel.ladder` for every
/// tunable number). First-time promotions pay focus coins into `CoinStore`.
final class ExperienceStore: ObservableObject {
    @Published private(set) var total: Int
    /// 0-based index into `FocusLevel.ladder`.
    @Published private(set) var levelIndex: Int
    /// Blocks at/above target since arriving at this level.
    @Published private(set) var wins: Int
    /// Blocks below target since arriving at this level.
    @Published private(set) var misses: Int
    /// How the latest reviewed block moved the ladder.
    @Published private(set) var lastOutcome: LevelOutcome?

    var level: FocusLevel { FocusLevel.ladder[levelIndex] }
    /// 1-based, for display ("Level 3 · Disciple").
    var levelNumber: Int { levelIndex + 1 }
    var nextLevel: FocusLevel? {
        levelIndex + 1 < FocusLevel.ladder.count ? FocusLevel.ladder[levelIndex + 1] : nil
    }
    var previousLevel: FocusLevel? {
        levelIndex > 0 ? FocusLevel.ladder[levelIndex - 1] : nil
    }

    /// Highest level index ever paid a promotion reward — the no-refarm rule.
    private var highestRewardedIndex: Int

    private static let totalKey = "experience.total"
    private static let levelKey = "experience.levelIndex"
    private static let winsKey = "experience.wins"
    private static let missesKey = "experience.misses"
    private static let rewardedKey = "experience.highestRewardedIndex"

    private let defaults: UserDefaults
    /// Where first-time promotion rewards are paid.
    private let coins: CoinStore

    init(defaults: UserDefaults = .standard, coins: CoinStore = CoinStore()) {
        self.defaults = defaults
        self.coins = coins
        total = defaults.integer(forKey: Self.totalKey)
        // Clamp in case the ladder shrank between builds.
        levelIndex = min(max(0, defaults.integer(forKey: Self.levelKey)), FocusLevel.ladder.count - 1)
        wins = defaults.integer(forKey: Self.winsKey)
        misses = defaults.integer(forKey: Self.missesKey)
        highestRewardedIndex = min(defaults.integer(forKey: Self.rewardedKey), FocusLevel.ladder.count - 1)
    }

    /// Bank a finished block: XP, plus one judged step on the ladder.
    func recordBlock(score: Int) {
        if score > 0 {
            total += score
        }

        let target = level.targetScore
        let met = score >= target
        var movement = LevelOutcome.Movement.stayed

        if met {
            wins += 1
            if nextLevel != nil {
                if wins >= level.winsToPromote {
                    levelIndex += 1
                    wins = 0
                    misses = 0
                    // The *destination* level's reward, first arrival only.
                    var paid = 0
                    if levelIndex > highestRewardedIndex {
                        paid = level.promotionReward
                        coins.earn(paid)
                        highestRewardedIndex = levelIndex
                    }
                    movement = .promoted(coinsAwarded: paid)
                }
            } else if wins >= level.winsToPromote {
                // Summit held: with no promotion to spend the streak on, it
                // wipes the slate instead — otherwise misses would ratchet
                // one-way toward a guaranteed demotion, and the banked wins
                // would pay out a spurious instant promotion if the ladder
                // ever grows a rung.
                wins = 0
                misses = 0
            }
        } else if levelIndex > 0 {
            // Level 1 is the floor — with nowhere to drop, misses aren't tracked.
            misses += 1
            if misses >= level.missesToDemote {
                levelIndex -= 1
                wins = 0
                misses = 0
                movement = .demoted
            }
        }

        lastOutcome = LevelOutcome(score: score, target: target, metTarget: met, movement: movement)
        persist()
    }

    private func persist() {
        defaults.set(total, forKey: Self.totalKey)
        defaults.set(levelIndex, forKey: Self.levelKey)
        defaults.set(wins, forKey: Self.winsKey)
        defaults.set(misses, forKey: Self.missesKey)
        defaults.set(highestRewardedIndex, forKey: Self.rewardedKey)
    }
}
