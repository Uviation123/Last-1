import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) var authVM
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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

                    if viewModel.hasLoggedToday {
                        todayLogCard
                            .slideIn(delay: 0.3)
                    } else {
                        emptyTodayCard
                            .slideIn(delay: 0.3)
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

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText)
                .font(.system(size: 14))
                .foregroundStyle(Color.appMuted)

            Text("Your 1% Today")
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.appForeground)
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
                        .foregroundStyle(Color.appForeground)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appPrimary)
                }
            }

            AppProgressBar(progress: viewModel.momentumPercentage, color: .appPrimary)

            Text(momentumSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.appMuted)
        }
        .padding(16)
        .glassCard()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.appPrimary.opacity(0.05))
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
                        .foregroundStyle(Color.appForeground)
                    Text("/ 1 log")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appMuted)
                }

                HStack(spacing: 4) {
                    ForEach(0..<1, id: \.self) { i in
                        Capsule()
                            .fill(viewModel.hasLoggedToday ? Color.appPrimary : Color.appSecondary)
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
                        .foregroundStyle(Color.appForeground)
                }

                Text("days in a row")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
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
                    .foregroundStyle(Color.appPrimary)
                    .font(.system(size: 16))
            }

            if let log = viewModel.todayLog {
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
                            .foregroundStyle(Color.appForeground)

                        if let note = log.note, !note.isEmpty {
                            Text(note)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appMuted)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    effortDots(level: log.effortLevel)
                }
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
                .foregroundStyle(Color.appMuted)

            Text("No log yet today")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appForeground)

            Text("Tap + to log your daily 1%")
                .font(.system(size: 13))
                .foregroundStyle(Color.appMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassCard()
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

    private func effortDots(level: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? Color.appPrimary : Color.appSecondary)
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
