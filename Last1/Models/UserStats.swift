import Foundation

// MARK: - UserStats
// Snapshot of a user's progress data used to render the shareable progress card.
// Constructed at each share trigger point from whatever data the hosting view already holds.

struct UserStats: Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let totalLogs: Int
    let momentumScore: Double      // 0–100
    let topCategory: String
    let identityStatement: String
    let weeklyLogCount: Int
}

// MARK: - Helpers

extension UserStats {

    /// Derives the most-logged category from an array of DailyLog entries.
    static func topCategory(from logs: [DailyLog]) -> String {
        guard !logs.isEmpty else { return "Fitness" }
        let freq = Dictionary(grouping: logs, by: { $0.category }).mapValues { $0.count }
        return freq.max(by: { $0.value < $1.value })?.key.displayName ?? "Fitness"
    }

    /// Reads the user's desired-identity statement from UserDefaults (written by OnboardingViewModel).
    static func identityStatement() -> String {
        let stored = UserDefaults.standard.string(forKey: "onboarding_desiredIdentity") ?? ""
        return stored.isEmpty ? "I show up every day." : stored
    }

    /// Convenience initialiser for the HomeView / MilestoneCelebration context.
    static func from(
        currentStreak: Int,
        longestStreak: Int,
        totalLogs: Int,
        momentumPercentage: Double,
        recentLogs: [DailyLog] = [],
        topCategoryOverride: String = "",
        weeklyLogCount: Int = 0
    ) -> UserStats {
        let top = topCategoryOverride.isEmpty
            ? topCategory(from: recentLogs)
            : topCategoryOverride

        return UserStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalLogs: totalLogs,
            momentumScore: min(momentumPercentage * 100, 100),
            topCategory: top,
            identityStatement: identityStatement(),
            weeklyLogCount: weeklyLogCount
        )
    }
}
