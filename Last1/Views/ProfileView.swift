import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(SubscriptionViewModel.self) private var subVM
    @Environment(\.colorScheme) var colorScheme
    @State private var growthVM = GrowthViewModel()
    @State private var weeklyVM = WeeklySummaryViewModel()
    @State private var userProfile: UserProfile?
    @State private var showSignOutAlert = false
    @State private var showSettings = false
    @State private var showSharePreview = false
    @State private var shareStats: UserStats?

    private let userRepo    = UserRepository()
    private let streakRepo  = StreakRepository()

    private var displayName: String {
        if let username = userProfile?.username, !username.isEmpty {
            return username
        }
        let email = userProfile?.email ?? authVM.email
        return email.isEmpty ? "User" : email
    }

    private var userInitial: String {
        String(displayName.first ?? "U").uppercased()
    }

    private var memberSince: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        if let createdAt = userProfile?.createdAt,
           let date = ISO8601DateFormatter().date(from: createdAt) {
            return "Growing since \(fmt.string(from: date))"
        }
        return "Growing since \(fmt.string(from: Date()))"
    }

    var body: some View {
        ZStack {
            Color.appBackground(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    pageHeader
                        .slideIn(delay: 0)

                    avatarCard
                        .slideIn(delay: 0.1)

                    statsRow
                        .slideIn(delay: 0.15)

                    signOutButton
                        .slideIn(delay: 0.35)

                    Text("Last 1% v1.0.0")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                        .padding(.top, 8)
                        .slideIn(delay: 0.4)

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
                async let profileFetch: () = {
                    userProfile = try? await userRepo.fetchProfile(userId: userId)
                }()
                async let growthFetch: () = growthVM.loadData(userId: userId)
                async let weeklyFetch: () = weeklyVM.loadData(userId: userId)
                async let streakFetch   = streakRepo.fetchStreak(userId: userId)

                _ = await (profileFetch, growthFetch, weeklyFetch)
                let streak = try? await streakFetch

                shareStats = UserStats.from(
                    currentStreak:     streak?.currentStreak ?? 0,
                    longestStreak:     streak?.longestStreak ?? 0,
                    totalLogs:         growthVM.totalLogs,
                    momentumPercentage: min(Double(streak?.currentStreak ?? 0) / 30.0, 1.0),
                    topCategoryOverride: growthVM.categoryBreakdown.first?.category.displayName ?? "",
                    weeklyLogCount:    weeklyVM.currentWeek?.logsCount ?? 0
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSharePreview) {
            if let stats = shareStats {
                ShareProgressPreviewSheet(stats: stats, showWatermark: !subVM.isSubscribed)
                    .presentationBackground(.clear)
                    .presentationDetents([.large])
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                Task { await authVM.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        Text("Profile")
            .font(.system(size: 24, weight: .bold))
            .tracking(-0.3)
            .foregroundStyle(Color.appPrimaryText(colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Avatar Card

    private var avatarCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appAccent(colorScheme).opacity(0.15))
                    .frame(width: 64, height: 64)

                Text(userInitial)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.appAccent(colorScheme))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(memberSince)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }

            Spacer()

            HStack(spacing: 4) {
                // Share progress
                if shareStats != nil {
                    Button {
                        showSharePreview = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appAccent(colorScheme))
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .animation(.easeOut(duration: 0.3), value: shareStats != nil)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            profileStatCard(value: "\(growthVM.totalLogs)", label: "Logs")
            profileStatCard(value: "\(bestStreak)", label: "Best Streak")
            profileStatCard(value: "\(growthVM.categoryBreakdown.count)", label: "Categories")
        }
    }

    private func profileStatCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appPrimaryText(colorScheme))

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Color.appMutedText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                Text("Sign Out")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.appDestructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var bestStreak: Int {
        weeklyVM.recentWeeks.map(\.logsCount).max() ?? 0
    }
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
}
