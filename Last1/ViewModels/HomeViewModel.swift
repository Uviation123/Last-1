import SwiftUI
import Observation

@Observable
class HomeViewModel {
    var todayLog: DailyLog?
    var streak: Streak?
    var isLoading = false
    var errorMessage: String?
    var showAddLog = false

    private let logRepo = DailyLogRepository()
    private let streakRepo = StreakRepository()

    var hasLoggedToday: Bool {
        todayLog != nil
    }

    var currentStreak: Int {
        streak?.currentStreak ?? 0
    }

    var longestStreak: Int {
        streak?.longestStreak ?? 0
    }

    var momentumPercentage: Double {
        min(Double(currentStreak) / 30.0, 1.0)
    }

    func loadData(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let logTask = logRepo.fetchTodayLog(userId: userId)
            async let streakTask = streakRepo.fetchStreak(userId: userId)

            todayLog = try await logTask
            streak = try await streakTask
        } catch {
            errorMessage = error.localizedDescription
        }

        // Sync any pending first log captured during onboarding (pre-auth).
        if todayLog == nil {
            await syncPendingFirstLog(userId: userId)
        }

        isLoading = false
    }

    // MARK: - Pending Onboarding Log Sync
    // If the user logged during onboarding before authenticating, a PendingLogData
    // is stored in UserDefaults under "pendingFirstLog". We insert it here on first
    // authenticated load, then clear the key to prevent duplicate inserts.
    private func syncPendingFirstLog(userId: UUID) async {
        let defaults = UserDefaults.standard
        guard
            let data = defaults.data(forKey: "pendingFirstLog"),
            let pending = try? JSONDecoder().decode(PendingLogData.self, from: data)
        else { return }

        let insert = DailyLogInsert(
            userId: userId,
            date: pending.date,
            category: pending.category,
            effortLevel: pending.effortLevel,
            note: pending.note,
            photoUrl: nil
        )

        do {
            let savedLog = try await logRepo.insertLog(insert)
            todayLog = savedLog

            // Update streak to reflect this first log
            let today = DateFormatting.todayString()
            let updatedStreak = StreakUpsert(
                userId: userId,
                currentStreak: (streak?.currentStreak ?? 0) + 1,
                longestStreak: max((streak?.longestStreak ?? 0), (streak?.currentStreak ?? 0) + 1),
                lastLogDate: today
            )
            try await streakRepo.upsertStreak(updatedStreak)
            streak = try await streakRepo.fetchStreak(userId: userId)

            // Clear the pending key only after a successful insert
            defaults.removeObject(forKey: "pendingFirstLog")
        } catch {
            // Non-fatal: the user can log manually from the home screen
        }
    }
}
