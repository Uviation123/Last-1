import SwiftUI
import Observation

@Observable
class HomeViewModel {
    var todayLog: DailyLog?
    var recentLogs: [DailyLog] = []
    var streak: Streak?
    var isLoading = false
    var errorMessage: String?
    var showAddLog = false
    var pendingMilestone: Milestone?

    private let logRepo = DailyLogRepository()
    private let streakRepo = StreakRepository()

    var totalLogs: Int = 0

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

    /// True when the user has a log history but missed at least one day before today,
    /// meaning their streak has been broken. Used to show the recovery card in HomeView.
    var streakIsBroken: Bool {
        guard !hasLoggedToday,
              let lastDate = streak?.lastLogDate else { return false }
        let yesterday = DateFormatting.daysAgo(1)
        let today = DateFormatting.todayString()
        return lastDate != today && lastDate != yesterday
    }

    func loadData(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let logTask    = logRepo.fetchTodayLog(userId: userId)
            async let streakTask = streakRepo.fetchStreak(userId: userId)
            // Fetch all logs in one call — count gives totalLogs, prefix(30) feeds the history list
            async let allLogsTask = logRepo.fetchRecentLogs(userId: userId, limit: 9999)

            todayLog = try await logTask
            streak   = try await streakTask
            let allLogs = try await allLogsTask
            let today   = DateFormatting.todayString()
            totalLogs   = allLogs.count
            recentLogs  = Array(allLogs.filter { $0.date != today }.prefix(30))
            // Persist the total so NotificationService can embed it in the streak-broken alert
            UserDefaults.standard.set(totalLogs, forKey: "notif_totalLogs")
        } catch {
            errorMessage = error.localizedDescription
        }

        // Sync any pending first log captured during onboarding (pre-auth).
        if todayLog == nil {
            await syncPendingFirstLog(userId: userId)
        }

        checkForMilestone()
        isLoading = false
    }

    // MARK: - Milestone Detection

    private func checkForMilestone() {
        guard hasLoggedToday else { return }
        guard let milestone = Milestone.milestone(for: currentStreak) else { return }
        guard !milestone.hasBeenShown else { return }
        pendingMilestone = milestone
    }

    func dismissMilestone() {
        pendingMilestone?.markAsShown()
        pendingMilestone = nil
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
