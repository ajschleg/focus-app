import SwiftUI

/// One rung of the guild ladder — the league system (CONCEPT.md §5D) layered
/// on top of XP, in the spirit of ranked ladders from Apex/Siege.
///
/// EVERYTHING that defines a level lives in the `ladder` table below: rename,
/// re-icon, retint, or retune by editing one row and nothing else.
///
/// Mechanics (driven by `ExperienceStore.recordBlock`):
/// - Every reviewed block compares its final score to the current level's
///   `targetScore` (meeting it exactly counts).
/// - Hit the target `winsToPromote` times at a level → promote.
/// - Miss it `missesToDemote` times → demote one level (level 1 is the floor).
///   Both counters reset whenever you change level, in either direction.
/// - Promotion pays the *destination* level's `promotionReward` in focus
///   coins, but only the first time that level is ever reached — bouncing
///   between two levels can't farm coins.
struct FocusLevel: Equatable {
    let name: String
    /// Placeholder artwork until real art exists — an SF symbol shown in the
    /// level badge. Swap for image assets later without touching mechanics.
    let systemImage: String
    /// Tints the whole app while at this level (applied at the root view).
    let tint: Color
    /// The block score to beat while at this level (>= counts as a win).
    let targetScore: Int
    /// Wins needed at this level to promote out of it.
    let winsToPromote: Int
    /// Misses tolerated at this level before demotion.
    let missesToDemote: Int
    /// Focus coins paid the first time the user ever reaches this level.
    let promotionReward: Int

    /// Level 1 → 10. Climbing gets harder: targets rise, promotions need a
    /// longer streak, the early grace of an extra allowed miss goes away.
    ///
    /// Top targets sit on the score lattice: natural finishes land on
    /// 100 − 8·leftApp − 4·pickups (multiples of 4 from 100), so 84/88/92
    /// make levels 8/9/10 genuinely distinct bars — 85/88/90 would not.
    static let ladder: [FocusLevel] = [
        FocusLevel(name: "Novice",      systemImage: "leaf.fill",        tint: .mint,   targetScore: 50, winsToPromote: 2, missesToDemote: 4, promotionReward: 0),
        FocusLevel(name: "Apprentice",  systemImage: "book.closed.fill", tint: .brown,  targetScore: 55, winsToPromote: 2, missesToDemote: 4, promotionReward: 20),
        FocusLevel(name: "Journeyman",  systemImage: "figure.walk",      tint: .green,  targetScore: 60, winsToPromote: 3, missesToDemote: 4, promotionReward: 30),
        FocusLevel(name: "Adept",       systemImage: "mountain.2.fill",  tint: .teal,   targetScore: 65, winsToPromote: 3, missesToDemote: 3, promotionReward: 40),
        FocusLevel(name: "Veteran",     systemImage: "wind",             tint: .blue,   targetScore: 70, winsToPromote: 4, missesToDemote: 3, promotionReward: 60),
        FocusLevel(name: "Expert",      systemImage: "flame.fill",       tint: .indigo, targetScore: 75, winsToPromote: 4, missesToDemote: 3, promotionReward: 80),
        FocusLevel(name: "Master",      systemImage: "moon.stars.fill",  tint: .purple, targetScore: 80, winsToPromote: 5, missesToDemote: 3, promotionReward: 100),
        FocusLevel(name: "Grandmaster", systemImage: "sun.max.fill",     tint: .orange, targetScore: 84, winsToPromote: 5, missesToDemote: 3, promotionReward: 150),
        FocusLevel(name: "Luminary",    systemImage: "sparkles",         tint: .red,    targetScore: 88, winsToPromote: 6, missesToDemote: 3, promotionReward: 200),
        // The top of the guild. A full winning streak here "holds the
        // title": it resets both counters instead of promoting.
        FocusLevel(name: "Paragon",     systemImage: "crown.fill",       tint: .yellow, targetScore: 92, winsToPromote: 6, missesToDemote: 3, promotionReward: 300),
    ]
}
