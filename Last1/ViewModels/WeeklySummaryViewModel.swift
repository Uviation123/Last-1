import SwiftUI
import Observation

@Observable
class WeeklySummaryViewModel {
    var currentWeek: WeeklyStat?
    var recentWeeks: [WeeklyStat] = []
    var suggestedFocus: String = ""
    var isLoading = false
    var errorMessage: String?

    private let weeklyRepo = WeeklyStatRepository()
    private let logRepo = DailyLogRepository()

    func loadData(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let currentTask = weeklyRepo.fetchCurrentWeek(userId: userId)
            async let recentTask = weeklyRepo.fetchWeeklyStats(userId: userId, limit: 8)

            currentWeek = try await currentTask
            recentWeeks = try await recentTask

            if currentWeek == nil {
                try await computeCurrentWeek(userId: userId)
            }

            computeSuggestedFocus()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func computeCurrentWeek(userId: UUID) async throws {
        let weekStart = DateFormatting.startOfWeek()
        let today = DateFormatting.todayString()
        let logs = try await logRepo.fetchLogs(userId: userId, from: weekStart, to: today)

        guard !logs.isEmpty else { return }

        let grouped = Dictionary(grouping: logs, by: \.category)
        let sorted = grouped.sorted { $0.value.count > $1.value.count }
        let strongest = sorted.first?.key.rawValue
        let weakest = sorted.last?.key.rawValue

        try await weeklyRepo.upsertWeeklyStat(
            userId: userId,
            weekStart: weekStart,
            logsCount: logs.count,
            strongest: strongest,
            weakest: weakest
        )

        currentWeek = try await weeklyRepo.fetchCurrentWeek(userId: userId)
    }

    private func computeSuggestedFocus() {
        if let weakest = currentWeek?.weakestCategory {
            let category = LogCategory(rawValue: weakest) ?? .other
            suggestedFocus = "Try focusing on \(category.displayName) this week to balance your growth."
        } else {
            suggestedFocus = "Start logging daily actions to see personalized suggestions."
        }
    }
}
