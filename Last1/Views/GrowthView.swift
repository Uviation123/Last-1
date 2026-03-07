import SwiftUI
import Charts

struct GrowthView: View {
    @Environment(AuthViewModel.self) var authVM
    @State private var viewModel = GrowthViewModel()
    @State private var chartProgress: Double = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    pageHeader
                        .slideIn(delay: 0)

                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.chartData.isEmpty {
                        emptyState
                    } else {
                        trendChartCard
                            .slideIn(delay: 0.1)

                        statsRow
                            .slideIn(delay: 0.2)

                        weekStreakCard
                            .slideIn(delay: 0.3)

                        if !viewModel.categoryBreakdown.isEmpty {
                            categoryDistributionCard
                                .slideIn(delay: 0.4)
                        }
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
            Text("Your Growth")
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.appForeground)

            Text("Track your progress over time")
                .font(.system(size: 14))
                .foregroundStyle(Color.appMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trend Chart Card

    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header row
            HStack {
                Text("Growth Trend")
                    .sectionLabel()

                Spacer()

                if !viewModel.filteredChartData.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: growthTrendPercent >= 0
                              ? "chart.line.uptrend.xyaxis"
                              : "chart.line.downtrend.xyaxis")
                            .font(.system(size: 11))
                        Text(growthTrendPercent >= 0
                             ? "+\(growthTrendPercent)%"
                             : "\(growthTrendPercent)%")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(growthTrendPercent >= 0 ? Color.appPrimary : Color.appDestructive)
                }
            }

            // Time range picker
            HStack(spacing: 0) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedRange = range
                            viewModel.selectedDataPoint = nil
                            chartProgress = 0
                        }
                        withAnimation(.easeInOut(duration: 1.0).delay(0.1)) {
                            chartProgress = 1.0
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(viewModel.selectedRange == range
                                             ? Color.appBackground
                                             : Color.appMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedRange == range
                                    ? Color.appPrimary
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.appSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 9))

            // Chart
            Chart {
                // Area fill
                ForEach(viewModel.filteredChartData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Effort", point.effortLevel)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.25), Color.appPrimary.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Line
                ForEach(viewModel.filteredChartData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Effort", point.effortLevel)
                    )
                    .foregroundStyle(Color.appPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Category-colored dots
                ForEach(viewModel.filteredChartData) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Effort", point.effortLevel)
                    )
                    .foregroundStyle(point.category.chartColor)
                    .symbolSize(viewModel.selectedDataPoint?.id == point.id ? 120 : 50)
                    .annotation(position: .top, spacing: 4) {
                        if viewModel.selectedDataPoint?.id == point.id {
                            selectionCallout(for: point)
                        }
                    }
                }

                // Average rule
                let avg = viewModel.filteredAverageEffort
                if avg > 0 {
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(Color.appMuted.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .trailing, alignment: .center) {
                            Text("Avg")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.appMuted)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                        .foregroundStyle(Color.appBorder.opacity(0.4))
                    AxisValueLabel(format: xAxisDateFormat, centered: false)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appMuted)
                }
            }
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                        .foregroundStyle(Color.appBorder.opacity(0.4))
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appMuted)
                }
            }
            .chartYScale(domain: 0.5...5.5)
            .frame(height: 180)
            .mask(
                Rectangle()
                    .scaleEffect(x: chartProgress, anchor: .leading)
            )
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPos = value.location.x - geo[proxy.plotFrame!].minX
                                    if let date: Date = proxy.value(atX: xPos) {
                                        viewModel.selectedDataPoint = viewModel.filteredChartData.min(by: {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        })
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation { viewModel.selectedDataPoint = nil }
                                    }
                                }
                        )
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    chartProgress = 1.0
                }
            }

            // Category dot legend
            if !viewModel.filteredChartData.isEmpty {
                let categories = Array(Set(viewModel.filteredChartData.map(\.category)))
                    .sorted { $0.displayName < $1.displayName }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories) { cat in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(cat.chartColor)
                                    .frame(width: 7, height: 7)
                                Text(cat.displayName)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.appMuted)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Selection Callout

    private func selectionCallout(for point: ChartDataPoint) -> some View {
        VStack(spacing: 3) {
            Text(point.date, format: .dateTime.month(.abbreviated).day())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.appForeground)

            HStack(spacing: 3) {
                Image(systemName: point.category.icon)
                    .font(.system(size: 9))
                    .foregroundStyle(point.category.chartColor)
                HStack(spacing: 1) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= point.effortLevel ? "star.fill" : "star")
                            .font(.system(size: 7))
                            .foregroundStyle(star <= point.effortLevel
                                             ? Color.appPrimary
                                             : Color.appMuted.opacity(0.4))
                    }
                }
            }

            if point.logCount > 1 {
                Text("\(point.logCount) logs")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.appMuted)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "scope",
                iconColor: .chart2,
                label: "Total Logs",
                value: "\(viewModel.totalLogs)"
            )

            statCard(
                icon: "trophy.fill",
                iconColor: .chart3,
                label: "Avg Effort",
                value: String(format: "%.1f", viewModel.averageEffort)
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }

    // MARK: - Week Streak Card

    private var weekStreakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .sectionLabel()

            HStack(spacing: 0) {
                ForEach(weekDays, id: \.day) { entry in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(entry.active
                                      ? Color.appPrimary.opacity(0.2)
                                      : Color.appSecondary)
                                .frame(width: 40, height: 40)

                            if entry.active {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.appPrimary)
                            } else {
                                Text("—")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.appMuted)
                            }
                        }

                        Text(entry.day)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Category Distribution Card

    private var categoryDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Distribution")
                .sectionLabel()

            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.categoryBreakdown.enumerated()), id: \.element.id) { i, item in
                        let width = geo.size.width * (item.percentage / 100)
                        Rectangle()
                            .fill(item.category.chartColor)
                            .frame(width: max(width, 0))
                            .cornerRadius(i == 0 ? 4 : 0, corners: [.topLeft, .bottomLeft])
                            .cornerRadius(i == viewModel.categoryBreakdown.count - 1 ? 4 : 0,
                                          corners: [.topRight, .bottomRight])
                    }
                }
            }
            .frame(height: 12)
            .clipShape(Capsule())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(viewModel.categoryBreakdown) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.category.chartColor)
                            .frame(width: 8, height: 8)
                        Text("\(item.category.displayName) \(Int(item.percentage))%")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMuted)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Empty / Loading States

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.appMuted)

            Text("No data yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appForeground)

            Text("Start logging daily actions to see your growth")
                .font(.system(size: 14))
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .glassCard()
        .slideIn(delay: 0.1)
    }

    private var loadingState: some View {
        ProgressView()
            .tint(Color.appPrimary)
            .padding(40)
    }

    // MARK: - Computed Helpers

    private var weekDays: [(day: String, active: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        let loggedDates = Set(viewModel.chartData.map {
            DateFormatting.dateString(from: $0.date)
        })
        let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
            let dateString = DateFormatting.dateString(from: date)
            let weekday = calendar.component(.weekday, from: date) - 1
            return (day: dayLetters[weekday], active: loggedDates.contains(dateString))
        }
    }

    private var growthTrendPercent: Int {
        let data = viewModel.filteredChartData
        guard data.count >= 2 else { return 0 }
        let recent = data.suffix(max(data.count / 2, 1))
        let earlier = data.prefix(max(data.count / 2, 1))
        let recentAvg = recent.map(\.effortLevel).reduce(0, +) / max(recent.count, 1)
        let earlierAvg = earlier.map(\.effortLevel).reduce(0, +) / max(earlier.count, 1)
        guard earlierAvg > 0 else { return 0 }
        return Int((Double(recentAvg - earlierAvg) / Double(earlierAvg)) * 100)
    }

    private var xAxisValues: AxisMarkValues {
        switch viewModel.selectedRange {
        case .week:    return .stride(by: .day, count: 1)
        case .month:   return .stride(by: .day, count: 7)
        case .quarter: return .stride(by: .day, count: 21)
        }
    }

    private var xAxisDateFormat: Date.FormatStyle {
        switch viewModel.selectedRange {
        case .week:    return .dateTime.weekday(.abbreviated)
        case .month:   return .dateTime.month(.abbreviated).day()
        case .quarter: return .dateTime.month(.abbreviated).day()
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    GrowthView()
        .environment(AuthViewModel())
}
