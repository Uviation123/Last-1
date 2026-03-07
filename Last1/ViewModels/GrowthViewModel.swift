import SwiftUI
import Observation

enum TimeRange: String, CaseIterable {
    case week = "7D"
    case month = "30D"
    case quarter = "90D"

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let effortLevel: Int
    let category: LogCategory
    let logCount: Int
}

struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let category: LogCategory
    let count: Int
    let percentage: Double
}

@Observable
class GrowthViewModel {
    var chartData: [ChartDataPoint] = []
    var categoryBreakdown: [CategoryBreakdown] = []
    var totalLogs: Int = 0
    var averageEffort: Double = 0
    var selectedRange: TimeRange = .month
    var selectedDataPoint: ChartDataPoint?
    var isLoading = false
    var errorMessage: String?

    private let logRepo = DailyLogRepository()

    var filteredChartData: [ChartDataPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
        return chartData.filter { $0.date >= cutoff }
    }

    var filteredAverageEffort: Double {
        let data = filteredChartData
        guard !data.isEmpty else { return 0 }
        return Double(data.map(\.effortLevel).reduce(0, +)) / Double(data.count)
    }

    func loadData(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        selectedDataPoint = nil

        do {
            let startDate = DateFormatting.daysAgo(90)
            let endDate = DateFormatting.todayString()
            let logs = try await logRepo.fetchLogs(userId: userId, from: startDate, to: endDate)

            let groupedByDate = Dictionary(grouping: logs, by: \.date)
            chartData = groupedByDate.compactMap { dateString, entries in
                guard let date = DateFormatting.date(from: dateString) else { return nil }
                let avgEffort = entries.map(\.effortLevel).reduce(0, +) / max(entries.count, 1)
                let dominantCategory = entries
                    .reduce(into: [:]) { counts, log in counts[log.category, default: 0] += 1 }
                    .max(by: { $0.value < $1.value })?.key ?? entries[0].category
                return ChartDataPoint(
                    date: date,
                    effortLevel: avgEffort,
                    category: dominantCategory,
                    logCount: entries.count
                )
            }.sorted { $0.date < $1.date }

            totalLogs = logs.count

            if !logs.isEmpty {
                averageEffort = Double(logs.map(\.effortLevel).reduce(0, +)) / Double(logs.count)
            }

            let grouped = Dictionary(grouping: logs, by: \.category)
            categoryBreakdown = grouped.map { category, items in
                CategoryBreakdown(
                    category: category,
                    count: items.count,
                    percentage: Double(items.count) / Double(max(totalLogs, 1)) * 100
                )
            }.sorted { $0.count > $1.count }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
