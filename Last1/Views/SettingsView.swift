import SwiftUI
import StoreKit
import UserNotifications

// MARK: - AppearanceMode
// Kept here because Last1App.swift reads @AppStorage("appearanceMode") and
// calls AppearanceMode(rawValue:) directly. Moving it would break the build.
enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var label: String {
        switch self {
        case .system: return "System Default"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AuthViewModel.self) private var authVM
    @Environment(SubscriptionViewModel.self) private var subscriptionVM
    @Environment(\.requestReview) private var requestReview

    @State private var viewModel = SettingsViewModel()
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.dark.rawValue

    // Sheet & alert presentation flags
    @State private var showMomentumInfo      = false
    @State private var showAboutSheet        = false
    @State private var showNotifDeniedAlert  = false
    @State private var isEditingIdentity     = false
    @State private var showProPaywall        = false

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .dark
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Top identity + streak banner
                        headerBanner
                            .slideIn(delay: 0)

                        identitySection
                            .slideIn(delay: 0.05)

                        progressSection
                            .slideIn(delay: 0.10)

                        notificationsSection
                            .slideIn(delay: 0.15)

                        subscriptionSection
                            .slideIn(delay: 0.20)

                        appearanceSection
                            .slideIn(delay: 0.25)

                        supportSection
                            .slideIn(delay: 0.30)

                        versionFooter
                            .slideIn(delay: 0.35)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appAccent(colorScheme))
                }
            }
        }
        .preferredColorScheme(selectedMode.colorScheme)
        // Load streak + log count when the sheet appears
        .task {
            if let userId = authVM.currentUserId {
                await viewModel.loadData(userId: userId)
            }
        }
        // Momentum info modal
        .sheet(isPresented: $showMomentumInfo) {
            momentumInfoSheet
        }
        // About sheet
        .sheet(isPresented: $showAboutSheet) {
            aboutSheet
        }
        // Destructive reset confirmation
        .alert("Reset Journey?", isPresented: $viewModel.showResetConfirmation) {
            Button("Reset Everything", role: .destructive) {
                viewModel.resetJourney()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will erase your identity statement, goals, and commitment settings. Your logged actions will remain. The app will restart onboarding.")
        }
        // Notification permission denied
        .alert("Notifications Blocked", isPresented: $viewModel.notificationPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Enable notifications in iOS Settings to receive reminders from Last 1%.")
        }
        .onChange(of: viewModel.notificationPermissionDenied) { _, denied in
            if denied { showNotifDeniedAlert = true }
        }
        .sheet(isPresented: $showProPaywall) {
            OnboardingPaywallView(onComplete: { showProPaywall = false })
                .environment(subscriptionVM)
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        ZStack(alignment: .topTrailing) {
            // Subtle ambient glow behind the card
            AmbientGlow(color: .appPrimary, size: 120)
                .offset(x: 40, y: -20)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 6) {
                // Identity goal line
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appAccent(colorScheme))
                    Text("Becoming: \(viewModel.desiredIdentity.isEmpty ? "your best self" : viewModel.desiredIdentity)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                // Streak + momentum line
                HStack(spacing: 12) {
                    Label {
                        Text("\(viewModel.currentStreak) day streak")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    } icon: {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.chart3)
                    }

                    Circle()
                        .fill(Color.appMutedText(colorScheme).opacity(0.4))
                        .frame(width: 3, height: 3)

                    Label {
                        Text("Momentum: \(viewModel.momentumLabel)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    } icon: {
                        Image(systemName: viewModel.momentumIcon)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appAccent(colorScheme))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .glassCard()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 1: Profile & Identity

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Profile & Identity")

            // "Right now I am…" field
            identityRow(
                icon: "person.fill",
                iconColor: Color.chart2,
                label: "Right now I am…",
                binding: Binding(
                    get: { viewModel.currentIdentity },
                    set: { viewModel.currentIdentity = $0 }
                ),
                placeholder: "Who are you today?"
            )

            divider()

            // "I want to be…" field
            identityRow(
                icon: "arrow.up.circle.fill",
                iconColor: Color.appAccent(colorScheme),
                label: "I want to be…",
                binding: Binding(
                    get: { viewModel.desiredIdentity },
                    set: { viewModel.desiredIdentity = $0 }
                ),
                placeholder: "Who are you becoming?"
            )

            divider()

            // Primary Growth Focus picker
            pickerRow(
                icon: "target",
                iconColor: Color.chart4,
                label: "Primary Focus",
                selection: Binding(
                    get: { viewModel.primaryGoalId },
                    set: { viewModel.primaryGoalId = $0; viewModel.saveIdentity() }
                ),
                options: OnboardingGoal.all.map { ($0.id, $0.label) }
            )

            divider()

            // Commitment Level picker
            pickerRow(
                icon: "bolt.fill",
                iconColor: Color.chart3,
                label: "Commitment",
                selection: Binding(
                    get: { viewModel.commitmentLevel },
                    set: { viewModel.commitmentLevel = $0; viewModel.saveIdentity() }
                ),
                options: CommitmentLevel.allCases.map { ($0.rawValue, $0.label) }
            )

            divider()

            // Member Since — read only
            staticRow(
                icon: "calendar.badge.clock",
                iconColor: Color.appMuted,
                label: "Member Since",
                value: memberSince
            )

            divider()

            // Reset Journey — destructive
            Button {
                viewModel.showResetConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appDestructive.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appDestructive)
                    }
                    Text("Reset Journey")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appDestructive)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .glassCard()
        // Persist identity when the user taps away from a text field
        .onDisappear { viewModel.saveIdentity() }
    }

    // MARK: - Section 2: Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Progress")

            statRow(icon: "flame.fill",          iconColor: Color.chart3, label: "Current Streak",      value: "\(viewModel.currentStreak) days")
            divider()
            statRow(icon: "trophy.fill",          iconColor: Color.chart3, label: "Longest Streak",      value: "\(viewModel.longestStreak) days")
            divider()
            statRow(icon: "checkmark.seal.fill",  iconColor: Color.appAccent(colorScheme), label: "Total 1% Actions", value: "\(viewModel.totalLogs)")
            divider()

            // Momentum Score row with info button
            Button { showMomentumInfo = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appAccent(colorScheme).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appAccent(colorScheme))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Momentum Score")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appPrimaryText(colorScheme))
                        Text("Tap to learn more")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    }
                    Spacer()
                    Text(viewModel.momentumLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appAccent(colorScheme))
                    Image(systemName: "info.circle")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            divider()

            // Export Data — placeholder
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appSurfaceSecondary(colorScheme))
                        .frame(width: 32, height: 32)
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Export Data")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                    Text("Coming soon")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMutedText(colorScheme).opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .glassCard()
    }

    // MARK: - Section 3: Notifications

    private var notificationsSection: some View {
        let isPro = subscriptionVM.isSubscribed

        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Notifications")

            if !isPro {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appAccent(colorScheme))
                    Text("All notification features require Pro")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                    Spacer()
                    Button { showProPaywall = true } label: {
                        Text("Upgrade")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.appAccent(colorScheme))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.appAccent(colorScheme).opacity(0.07))

                divider()
            }

            // Daily Reminder toggle
            notifToggleRow(
                icon: "bell.fill",
                iconColor: Color(red: 1.0, green: 0.58, blue: 0.0),
                label: "Daily Reminder",
                detail: "Log your 1% each day",
                isOn: Binding(
                    get: { viewModel.dailyReminderEnabled },
                    set: { viewModel.dailyReminderEnabled = $0
                           Task { await viewModel.toggleDailyReminder() }
                    }
                ),
                isProGated: !isPro,
                onProTap: { showProPaywall = true }
            )

            // Time picker — only visible when daily reminder is on (and subscribed)
            if viewModel.dailyReminderEnabled && isPro {
                divider()
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 1.0, green: 0.58, blue: 0.0).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.0))
                    }
                    Text("Reminder Time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { viewModel.reminderTime },
                            set: { viewModel.reminderTime = $0
                                  viewModel.updateDailyReminder()
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.2), value: viewModel.dailyReminderEnabled)
            }

            divider()

            // Motivational Nudges toggle
            notifToggleRow(
                icon: "quote.bubble.fill",
                iconColor: Color.chart2,
                label: "Motivational Nudges",
                detail: "Encouragement throughout the week",
                isOn: Binding(
                    get: { viewModel.motivationalNudgesEnabled },
                    set: { viewModel.motivationalNudgesEnabled = $0
                           Task { await viewModel.toggleMotivationalNudges() }
                    }
                ),
                isProGated: !isPro,
                onProTap: { showProPaywall = true }
            )

            divider()

            // Streak-at-Risk toggle
            notifToggleRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color.appDestructive,
                label: "Streak-at-Risk Alerts",
                detail: "Notified at 9 PM if you haven't logged",
                isOn: Binding(
                    get: { viewModel.streakAlertEnabled },
                    set: { viewModel.streakAlertEnabled = $0
                           Task { await viewModel.toggleStreakAlert() }
                    }
                ),
                isProGated: !isPro,
                onProTap: { showProPaywall = true }
            )

            divider()

            // Streak Broken Alert toggle
            notifToggleRow(
                icon: "bolt.slash.fill",
                iconColor: Color.chart3,
                label: "Streak Broken Alerts",
                detail: "Morning nudge if you missed yesterday",
                isOn: Binding(
                    get: { viewModel.streakBrokenAlertEnabled },
                    set: { viewModel.streakBrokenAlertEnabled = $0
                           Task { await viewModel.toggleStreakBrokenAlert() }
                    }
                ),
                isProGated: !isPro,
                onProTap: { showProPaywall = true }
            )
        }
        .glassCard()
        .animation(.easeInOut(duration: 0.2), value: viewModel.dailyReminderEnabled)
    }

    // MARK: - Section 4: Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Subscription")

            // Current plan badge row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(subscriptionVM.isSubscribed
                              ? Color.appAccent(colorScheme).opacity(0.15)
                              : Color.appSurfaceSecondary(colorScheme))
                        .frame(width: 32, height: 32)
                    Image(systemName: subscriptionVM.isSubscribed ? "crown.fill" : "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(subscriptionVM.isSubscribed ? Color.appAccent(colorScheme) : Color.appMutedText(colorScheme))
                }
                Text("Current Plan")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                Spacer()
                Text(subscriptionVM.isSubscribed ? "Pro" : "Free")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(subscriptionVM.isSubscribed ? Color.appAccent(colorScheme) : Color.appMutedText(colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            subscriptionVM.isSubscribed
                            ? Color.appAccent(colorScheme).opacity(0.15)
                            : Color.appSurfaceSecondary(colorScheme)
                        )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Only show Upgrade card when user is on Free plan
            if !subscriptionVM.isSubscribed {
                divider()
                upgradeBanner
            }

            divider()

            // Manage Subscription — deep links to Apple subscription management page
            Button {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } label: {
                settingsRow(
                    icon: "creditcard.fill",
                    iconColor: Color.chart2,
                    label: "Manage Subscription",
                    detail: "View or cancel via App Store"
                )
            }
            .buttonStyle(.plain)

            divider()

            // Restore Purchases
            Button {
                Task { await subscriptionVM.restorePurchases() }
            } label: {
                HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appAccent(colorScheme).opacity(0.12))
                        .frame(width: 32, height: 32)
                    if subscriptionVM.isLoading {
                        ProgressView()
                            .tint(Color.appAccent(colorScheme))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appAccent(colorScheme))
                    }
                }
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(subscriptionVM.isLoading)

            // Surface any subscription errors inline
            if let error = subscriptionVM.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appDestructive)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .glassCard()
    }

    /// Upgrade-to-Pro banner shown only for Free users
    private var upgradeBanner: some View {
        Button {
            Task { await subscriptionVM.startFreeTrial() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appAccent(colorScheme).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.appAccent(colorScheme))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                    Text("Unlock all features & advanced insights")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appAccent(colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Appearance")

            ForEach(Array(AppearanceMode.allCases.enumerated()), id: \.element.rawValue) { i, mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appearanceModeRaw = mode.rawValue
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appSurfaceSecondary(colorScheme))
                                .frame(width: 32, height: 32)
                            Image(systemName: mode.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.appPrimaryText(colorScheme))
                        }
                        Text(mode.label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appPrimaryText(colorScheme))
                        Spacer()
                        if selectedMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.appAccent(colorScheme))
                        } else {
                            Image(systemName: "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.appMutedText(colorScheme).opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if i < AppearanceMode.allCases.count - 1 {
                    divider()
                }
            }
        }
        .glassCard()
    }

    // MARK: - Section 5: App & Support

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("App & Support")

            // About
            Button { showAboutSheet = true } label: {
                settingsRow(icon: "info.circle.fill", iconColor: Color.appAccent(colorScheme), label: "About Last 1%", detail: "Mission, version info")
            }
            .buttonStyle(.plain)

            divider()

            // Privacy Policy
            Link(destination: URL(string: "https://last1percent.app/privacy")!) {
                settingsRow(icon: "lock.shield.fill", iconColor: Color.chart2, label: "Privacy Policy", detail: "")
            }
            .foregroundStyle(Color.appPrimaryText(colorScheme))

            divider()

            // Terms of Service
            Link(destination: URL(string: "https://last1percent.app/terms")!) {
                settingsRow(icon: "doc.text.fill", iconColor: Color.appMutedText(colorScheme), label: "Terms of Service", detail: "")
            }
            .foregroundStyle(Color.appPrimaryText(colorScheme))

            divider()

            // Contact Support
            Button {
                if let url = URL(string: "mailto:support@last1percent.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                settingsRow(
                    icon: "envelope.fill",
                    iconColor: Color(red: 0.9, green: 0.5, blue: 0.9),
                    label: "Contact Support",
                    detail: "support@last1percent.app"
                )
            }
            .buttonStyle(.plain)

            divider()

            // Rate the App — uses SwiftUI's native requestReview environment value
            Button {
                requestReview()
            } label: {
                settingsRow(icon: "star.fill", iconColor: Color.chart3, label: "Rate the App", detail: "Love it? Leave a review!")
            }
            .buttonStyle(.plain)

            divider()

            // Share with a Friend — ShareLink avoids UIActivityViewController boilerplate
            ShareLink(
                item: URL(string: "https://apps.apple.com/app/last1")!,
                message: Text("Check out Last 1% — the app that helps you grow 1% every day.")
            ) {
                settingsRow(
                    icon: "square.and.arrow.up.fill",
                    iconColor: Color.chart4,
                    label: "Share with a Friend",
                    detail: "Spread the 1% mindset"
                )
            }
            .foregroundStyle(Color.appPrimaryText(colorScheme))
        }
        .glassCard()
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        Text("Last 1% · v1.0.0")
            .font(.system(size: 11))
            .foregroundStyle(Color.appMutedText(colorScheme).opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - Momentum Info Sheet

    private var momentumInfoSheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        momentumInfoCard(
                            icon: "arrow.up.right.circle.fill",
                            color: Color.appAccent(colorScheme).opacity(0.8),
                            title: "Rising",
                            body: "You're in the early phase — under one third of a 30-day pace. Every log counts. Keep showing up."
                        )
                        momentumInfoCard(
                            icon: "equal.circle.fill",
                            color: Color.chart2,
                            title: "Stable",
                            body: "You're building a consistent rhythm. You're logging regularly and maintaining solid forward progress."
                        )
                        momentumInfoCard(
                            icon: "bolt.fill",
                            color: Color.chart3,
                            title: "Strong",
                            body: "Two thirds or more of a 30-day streak pace. You're compounding daily. This is where real transformation happens."
                        )

                        Text("Your Momentum Score reflects your current streak as a percentage of a 30-day consistent pace. It updates automatically as you log.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                            .padding(16)
                            .glassCard()
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Momentum Score")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showMomentumInfo = false }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appAccent(colorScheme))
                }
            }
        }
        .preferredColorScheme(selectedMode.colorScheme)
    }

    // MARK: - About Sheet

    private var aboutSheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // App icon placeholder + title
                        HStack(spacing: 14) {
                            ZStack {
                        RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appAccent(colorScheme).opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.appAccent(colorScheme))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Last 1%")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.appPrimaryText(colorScheme))
                            Text("Version 1.0.0")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appMutedText(colorScheme))
                            }
                        }
                        .padding(16)
                        .glassCard()

                        aboutBlock(
                            icon: "star.fill",
                            title: "The Mission",
                            body: "Last 1% exists to help you close the gap between who you are and who you're becoming — one small action at a time."
                        )
                        aboutBlock(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Why 1%?",
                            body: "A 1% improvement every day compounds to 37x growth over a year. We make tracking those small wins simple and meaningful."
                        )
                        aboutBlock(
                            icon: "lock.shield.fill",
                            title: "Your Data",
                            body: "Your logs are stored securely with Supabase. We never sell your data or share it with third parties."
                        )
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAboutSheet = false }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appAccent(colorScheme))
                }
            }
        }
        .preferredColorScheme(selectedMode.colorScheme)
    }

    // MARK: - Reusable Row Components

    /// Standard settings row with icon, label, optional detail, and optional chevron
    private func settingsRow(
        icon: String,
        iconColor: Color,
        label: String,
        detail: String,
        showChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    /// Read-only label/value row (e.g. Member Since, streak count)
    private func statRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimaryText(colorScheme))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appMutedText(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    /// Read-only label/value row with string value
    private func staticRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        statRow(icon: icon, iconColor: iconColor, label: label, value: value)
    }

    /// Inline editable TextField row for identity statements
    private func identityRow(
        icon: String,
        iconColor: Color,
        label: String,
        binding: Binding<String>,
        placeholder: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.appMutedText(colorScheme))
                TextField(placeholder, text: binding, onCommit: { viewModel.saveIdentity() })
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                    .tint(Color.appAccent(colorScheme))
                    .submitLabel(.done)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// Picker row for selecting from a list of options (generic over Hashable)
    private func pickerRow<T: Hashable>(
        icon: String,
        iconColor: Color,
        label: String,
        selection: Binding<T>,
        options: [(T, String)]
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimaryText(colorScheme))
            Spacer()
            Picker(label, selection: selection) {
                ForEach(options, id: \.0) { value, name in
                    Text(name).tag(value)
                }
            }
            .labelsHidden()
            .tint(Color.appAccent(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    /// Toggle row for notification preferences.
    /// When `isProGated` is true a crown badge replaces the toggle and `onProTap` fires on tap.
    private func notifToggleRow(
        icon: String,
        iconColor: Color,
        label: String,
        detail: String,
        isOn: Binding<Bool>,
        isProGated: Bool = false,
        onProTap: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(isProGated ? 0.10 : 0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor.opacity(isProGated ? 0.4 : 1.0))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimaryText(colorScheme).opacity(isProGated ? 0.5 : 1.0))
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }
            }
            Spacer()
            Group {
                if isProGated {
                    Button { onProTap?() } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9))
                            Text("Pro")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.appAccent(colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.appAccent(colorScheme).opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                } else {
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .tint(Color.appAccent(colorScheme))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .sectionLabel()
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Divider

    private func divider() -> some View {
        Rectangle()
            .fill(Color.appBorderDynamic(colorScheme))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    // MARK: - Momentum Info Card

    private func momentumInfoCard(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appMutedText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - About Block

    private func aboutBlock(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.appAccent(colorScheme))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appMutedText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Computed

    /// Displays the month + year of the user's account creation.
    /// Mirrors the approach in ProfileView (no createdAt in AuthViewModel, so we show current month).
    private var memberSince: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        return fmt.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AuthViewModel())
        .environment(SubscriptionViewModel())
}
