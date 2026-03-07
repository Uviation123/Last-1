import SwiftUI

// MARK: - Screen 6: Personalized Growth Result
// Display-only screen that synthesizes user's selections into a personalized
// "your journey" narrative. Animated momentum bars rise from zero to simulate
// momentum building. No user input — exists purely to build emotional investment.
struct OnboardingGrowthResultView: View {
    var onNext: () -> Void

    @Environment(OnboardingViewModel.self) private var vm

    @State private var momentumProgress: Double = 0
    @State private var streakVisible = false
    @State private var goalsVisible = false

    var body: some View {
        OnboardingScreenShell(
            title: "Your Growth Blueprint",
            subtitle: personalisedSubtitle,
            continueTitle: "Log My First 1%",
            onContinue: onNext
        ) {
            VStack(spacing: 20) {
                // Momentum projection card
                momentumCard
                    .slideIn(delay: 0.1)

                // Selected goals showcase
                if !vm.selectedGoals.isEmpty {
                    goalsCard
                        .slideIn(delay: 0.2)
                }

                // Commitment badge
                commitmentBadge
                    .slideIn(delay: 0.3)

                // Identity transformation teaser
                if !vm.desiredIdentity.isEmpty {
                    identityCard
                        .slideIn(delay: 0.4)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).delay(0.3)) {
                momentumProgress = 0.68
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                streakVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                goalsVisible = true
            }
        }
    }

    // MARK: Personalised subtitle

    private var personalisedSubtitle: String {
        let commitment = vm.commitmentLevelEnum
        if vm.selectedGoals.isEmpty {
            return "Here's what your \(commitment.label.lowercased()) daily practice will build."
        }
        return "Based on your goals, here's what your \(commitment.label.lowercased()) practice will achieve."
    }

    // MARK: Momentum Card

    private var momentumCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Projected Momentum")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appMuted)
                    .tracking(0.5)
                Spacer()
                Text("30 days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appMuted)
            }

            // Animated momentum bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSecondary)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.7), Color.appPrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * momentumProgress)
                        .shadow(color: Color.appPrimary.opacity(0.5), radius: 8)
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())

            HStack {
                Text("Day 1")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appMuted)
                Spacer()

                // Animated percentage label
                Text("\(Int(momentumProgress * 100))% potential")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.appPrimary)

                Spacer()
                Text("Day 30")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appMuted)
            }

            // Streak projection row
            if streakVisible {
                Divider().overlay(Color.appBorder.opacity(0.4))

                HStack(spacing: 20) {
                    ProjectionStat(value: "30", label: "day streak", icon: "flame.fill", color: .orange)
                    ProjectionStat(value: "37x", label: "compounded", icon: "chart.line.uptrend.xyaxis", color: Color.appPrimary)
                    ProjectionStat(value: "1%", label: "every day", icon: "star.fill", color: .yellow)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(18)
        .glassCard()
    }

    // MARK: Goals Card

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Focus Areas")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appMuted)
                .tracking(0.5)

            let selectedGoalObjects = OnboardingGoal.all.filter { vm.selectedGoals.contains($0.id) }

            OnboardingFlowLayout(spacing: 8) {
                ForEach(selectedGoalObjects) { goal in
                    HStack(spacing: 6) {
                        Image(systemName: goal.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(goal.color)
                        Text(goal.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appForeground.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(goal.color.opacity(0.12))
                            .overlay(Capsule().strokeBorder(goal.color.opacity(0.3), lineWidth: 1))
                    )
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    // MARK: Commitment Badge

    private var commitmentBadge: some View {
        let level = vm.commitmentLevelEnum
        let accentColor: Color = {
            switch level {
            case .light:    return Color(red: 0.4, green: 0.8, blue: 1.0)
            case .moderate: return Color.appPrimary
            case .allIn:    return Color(red: 1.0, green: 0.6, blue: 0.3)
            }
        }()

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Commitment: \(level.label)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appForeground)
                Text(level.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: Identity Card

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Transformation")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appMuted)
                .tracking(0.5)

            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.appPrimary)

                Text(vm.desiredIdentity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appForeground)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Projection Stat
private struct ProjectionStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.appForeground)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingGrowthResultView(onNext: {})
            .environment({
                let vm = OnboardingViewModel()
                vm.selectedGoals = ["fitness", "learning", "mindfulness"]
                vm.commitmentLevel = 2
                vm.desiredIdentity = "Someone who shows up every single day"
                return vm
            }())
    }
    .preferredColorScheme(.dark)
}
