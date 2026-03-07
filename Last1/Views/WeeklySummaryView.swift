import SwiftUI

struct WeeklySummaryView: View {
    @Environment(AuthViewModel.self) var authVM
    @State private var viewModel = WeeklySummaryViewModel()
    @State private var logsCountAnimated = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    pageHeader
                        .slideIn(delay: 0)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.appPrimary)
                            .padding(40)
                    } else if viewModel.currentWeek == nil {
                        emptyState
                            .slideIn(delay: 0.1)
                    } else {
                        totalLogsCard
                            .slideIn(delay: 0.1)

                        if let week = viewModel.currentWeek {
                            if let strongest = week.strongestCategory {
                                strongestCategoryCard(strongest)
                                    .slideIn(delay: 0.2)
                            }

                            if let weakest = week.weakestCategory {
                                suggestedFocusCard(weakest)
                                    .slideIn(delay: 0.3)
                            }
                        }

                        projectionCard
                            .slideIn(delay: 0.4)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            if let userId = authVM.currentUserId {
                await viewModel.loadData(userId: userId)
            }
        }
        .refreshable {
            if let userId = authVM.currentUserId {
                await viewModel.loadData(userId: userId)
            }
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Weekly Summary")
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.appForeground)

            Text(weekRangeText)
                .font(.system(size: 14))
                .foregroundStyle(Color.appMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Total Logs Card

    private var totalLogsCard: some View {
        ZStack {
            // Background glows
            Circle()
                .fill(Color.appPrimary.opacity(0.05))
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .offset(x: 60, y: -30)

            Circle()
                .fill(Color.chart2.opacity(0.05))
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .offset(x: -60, y: 30)

            VStack(spacing: 8) {
                Text("Total Logs This Week")
                    .sectionLabel()

                Text("\(viewModel.currentWeek?.logsCount ?? 0)")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.appForeground)
                    .contentTransition(.numericText())

                if let lastWeekCount = lastWeekCount, lastWeekCount > 0 {
                    let current = viewModel.currentWeek?.logsCount ?? 0
                    let change = current - lastWeekCount
                    let pct = Int((Double(change) / Double(lastWeekCount)) * 100)

                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                            .font(.system(size: 12))
                        Text("\(change >= 0 ? "+" : "")\(pct)% vs last week")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(change >= 0 ? Color.appPrimary : Color.chart4)
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard()
    }

    // MARK: - Strongest Category Card

    private func strongestCategoryCard(_ categoryRaw: String) -> some View {
        let category = LogCategory(rawValue: categoryRaw) ?? .other

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.chart3.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "star.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.chart3)
            }
            .flexibleWidth(false)

            VStack(alignment: .leading, spacing: 4) {
                Text("Strongest Category")
                    .sectionLabel()

                Text(category.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.appForeground)

                Text("Your top area this week — keep the momentum going.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Suggested Focus Card

    private func suggestedFocusCard(_ categoryRaw: String) -> some View {
        let category = LogCategory(rawValue: categoryRaw) ?? .other

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.chart2.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.chart2)
            }
            .flexibleWidth(false)

            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Focus")
                    .sectionLabel()

                Text(category.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.appForeground)

                Text(viewModel.suggestedFocus)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Projection Card

    private var projectionCard: some View {
        ZStack {
            // Subtle gradient overlay
            LinearGradient(
                colors: [Color.appPrimary.opacity(0.06), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: "rocket.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.appPrimary)
                }

                VStack(spacing: 6) {
                    Text("Projection")
                        .sectionLabel()

                    Text("At this rate, you will be \(projectionMultiplier)x better in one year.")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.appForeground)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Keep stacking your 1% gains")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appMuted)
                }
            }
            .padding(24)
        }
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 44))
                .foregroundStyle(Color.appMuted)

            Text("No weekly data yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appForeground)

            Text("Complete a week of logging to see your summary")
                .font(.system(size: 14))
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .glassCard()
    }

    // MARK: - Helpers

    private var weekRangeText: String {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOffset = -(weekday - calendar.firstWeekday)
        guard let startOfWeek = calendar.date(byAdding: .day, value: startOffset, to: today),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return ""
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: startOfWeek)) – \(fmt.string(from: endOfWeek))"
    }

    private var lastWeekCount: Int? {
        viewModel.recentWeeks.dropFirst().first?.logsCount
    }

    private var projectionMultiplier: Int {
        let logsPerWeek = viewModel.currentWeek?.logsCount ?? 1
        let weeksPerYear = 52
        let dailyGain = 0.01
        let totalDays = logsPerWeek * weeksPerYear / 7
        let result = pow(1.0 + dailyGain, Double(totalDays))
        return max(Int(result.rounded()), 2)
    }
}

// MARK: - Layout helper

extension View {
    func flexibleWidth(_ flexible: Bool) -> some View {
        self.frame(maxWidth: flexible ? .infinity : nil)
    }
}

#Preview {
    WeeklySummaryView()
        .environment(AuthViewModel())
}
