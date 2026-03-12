import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(SubscriptionViewModel.self) private var subVM
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = HomeViewModel()
    @State private var selectedLog: DailyLog?
    @State private var showProPaywall = false

    var body: some View {
        ZStack {
            Color.appBackground(colorScheme).ignoresSafeArea()

            // Ambient glow
            AmbientGlow()
                .frame(width: 160, height: 160)
                .position(x: UIScreen.main.bounds.width / 2, y: 80)

            ScrollView {
                VStack(spacing: 12) {
                    greetingHeader
                        .slideIn(delay: 0)

                    momentumCard
                        .slideIn(delay: 0.1)

                    todayStreakRow
                        .slideIn(delay: 0.2)

                    if viewModel.streakIsBroken {
                        streakBrokenCard
                            .slideIn(delay: 0.3)
                    }

                    if viewModel.hasLoggedToday {
                        todayLogCard
                            .slideIn(delay: viewModel.streakIsBroken ? 0.4 : 0.3)
                    } else {
                        emptyTodayCard
                            .slideIn(delay: viewModel.streakIsBroken ? 0.4 : 0.3)
                    }

                    if !viewModel.recentLogs.isEmpty {
                        logHistorySection
                            .slideIn(delay: 0.4)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            // Milestone celebration overlay
            if let milestone = viewModel.pendingMilestone {
                MilestoneCelebrationView(
                    milestone: milestone,
                    onDismiss: { viewModel.dismissMilestone() },
                    stats: UserStats.from(
                        currentStreak:     viewModel.currentStreak,
                        longestStreak:     viewModel.longestStreak,
                        totalLogs:         viewModel.totalLogs,
                        momentumPercentage: viewModel.momentumPercentage,
                        recentLogs:        viewModel.recentLogs
                    )
                )
                .transition(.opacity)
                .zIndex(10)
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .didSaveLog)) { _ in
            Task {
                if let userId = authVM.currentUserId {
                    await viewModel.loadData(userId: userId)
                }
            }
        }
        .sheet(item: $selectedLog) { log in
            LogDetailView(log: log)
                .environment(authVM)
        }
        .sheet(isPresented: $showProPaywall) {
            OnboardingPaywallView(onComplete: { showProPaywall = false })
                .environment(subVM)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText)
                .font(.system(size: 14))
                .foregroundStyle(Color.appMutedText(colorScheme))

            Text("Your 1% Today")
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.appPrimaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Momentum Card

    private var momentumCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Momentum")
                        .sectionLabel()

                    Text("\(Int(viewModel.momentumPercentage * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appAccent(colorScheme).opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent(colorScheme))
                }
            }

            AppProgressBar(progress: viewModel.momentumPercentage, color: Color.appAccent(colorScheme))

            Text(momentumSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.appMutedText(colorScheme))
        }
        .padding(16)
        .glassCard()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.appAccent(colorScheme).opacity(0.05))
                .frame(width: 80, height: 80)
                .offset(x: 20, y: -20)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Today + Streak Row

    private var todayStreakRow: some View {
        HStack(spacing: 12) {
            // Today logs
            VStack(alignment: .leading, spacing: 6) {
                Text("Today")
                    .sectionLabel()

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(viewModel.hasLoggedToday ? "1" : "0")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                    Text("/ 1 log")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }

                HStack(spacing: 4) {
                    ForEach(0..<1, id: \.self) { i in
                        Capsule()
                            .fill(viewModel.hasLoggedToday ? Color.appAccent(colorScheme) : Color.appSurfaceSecondary(colorScheme))
                            .frame(height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassCard()

            // Streak
            VStack(alignment: .leading, spacing: 6) {
                Text("Streak")
                    .sectionLabel()

                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.chart3)

                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                }

                Text("days in a row")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassCard()
        }
    }

    // MARK: - Today's Log Card

    private var todayLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Log")
                    .sectionLabel()

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appAccent(colorScheme))
                    .font(.system(size: 16))
            }

            if let log = viewModel.todayLog {
                Button {
                    selectedLog = log
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(log.category.chartColor.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: log.category.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(log.category.chartColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.category.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.appPrimaryText(colorScheme))

                            if let note = log.note, !note.isEmpty {
                                Text(note)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appMutedText(colorScheme))
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        effortDots(level: log.effortLevel)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Empty Today Card

    private var emptyTodayCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 36))
                .foregroundStyle(Color.appMutedText(colorScheme))

            Text("No log yet today")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText(colorScheme))

            Text("Tap + to log your daily 1%")
                .font(.system(size: 13))
                .foregroundStyle(Color.appMutedText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassCard()
    }

    // MARK: - Streak Broken Card

    private var streakBrokenCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.chart3.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.chart3)
                }

                Text("Even the best slip up.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
            }

            Text("You've logged \(viewModel.totalLogs) total day\(viewModel.totalLogs == 1 ? "" : "s") — that growth is real and it's not going anywhere.")
                .font(.system(size: 13))
                .foregroundStyle(Color.appMutedText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text("Start your next streak today.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appAccent(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.chart3.opacity(0.06))
                .frame(width: 80, height: 80)
                .offset(x: 20, y: -20)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Log History Section

    private let freeHistoryLimit = 7

    private var logHistorySection: some View {
        let logsToShow = subVM.isSubscribed
            ? viewModel.recentLogs
            : Array(viewModel.recentLogs.prefix(freeHistoryLimit))
        let hasMoreLocked = !subVM.isSubscribed && viewModel.recentLogs.count > freeHistoryLimit

        return VStack(alignment: .leading, spacing: 10) {
            Text("Log History")
                .sectionLabel()
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(logsToShow) { log in
                    logHistoryRow(log)
                }

                if hasMoreLocked {
                    Divider()
                        .padding(.vertical, 2)

                    Button {
                        showProPaywall = true
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appAccent(colorScheme).opacity(0.12))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.appAccent(colorScheme))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock Full History")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                                Text("\(viewModel.recentLogs.count - freeHistoryLimit) more entries with Pro")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.appMutedText(colorScheme))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.appAccent(colorScheme))
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func logHistoryRow(_ log: DailyLog) -> some View {
        Button {
            selectedLog = log
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(log.category.chartColor.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: log.category.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(log.category.chartColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(log.category.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appPrimaryText(colorScheme))

                        Spacer()

                        Text(relativeDate(for: log.date))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    }

                    if let note = log.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                            .lineLimit(1)
                    }
                }

                effortDots(level: log.effortLevel)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.appMutedText(colorScheme).opacity(0.6))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var momentumSubtitle: String {
        let pct = viewModel.momentumPercentage
        if pct >= 0.8 { return "You're on fire — incredible momentum!" }
        if pct >= 0.5 { return "You're building strong momentum this week" }
        if pct >= 0.2 { return "Keep showing up — every day counts" }
        return "Start today and build your streak"
    }

    private func relativeDate(for dateString: String) -> String {
        let today = DateFormatting.todayString()
        let yesterday = DateFormatting.daysAgo(1)

        if dateString == today { return "Today" }
        if dateString == yesterday { return "Yesterday" }

        guard let date = DateFormatting.date(from: dateString) else {
            return dateString
        }

        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 {
            return DateFormatting.weekday(from: dateString)
        }

        return DateFormatting.displayString(from: dateString)
    }

    private func effortDots(level: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? Color.appAccent(colorScheme) : Color.appSurfaceSecondary(colorScheme))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - LogCategory chart color helper

extension LogCategory {
    var chartColor: Color {
        switch self {
        case .fitness:      return Color(red: 0.40, green: 0.78, blue: 1.00) // light blue
        case .learning:     return Color(red: 0.55, green: 0.92, blue: 0.18) // lime green
        case .mindfulness:  return Color(red: 0.78, green: 0.18, blue: 0.92) // magenta purple
        case .nutrition:    return Color(red: 0.82, green: 0.71, blue: 0.52) // desert tan
        case .productivity: return .chart2                                    // blue/indigo
        case .creativity:   return Color(red: 1.00, green: 0.67, blue: 0.78) // soft pink
        case .social:       return .chart4                                    // pink/rose
        case .other:        return .appMuted
        }
    }
}

#Preview {
    HomeView()
        .environment(AuthViewModel())
}
