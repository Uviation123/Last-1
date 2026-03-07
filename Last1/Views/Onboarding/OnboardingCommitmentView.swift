import SwiftUI

// MARK: - Screen 5: Commitment Level
// Three-option card picker (Light / Moderate / All-In) with animated intensity bars
// that grow taller as the commitment level increases.
struct OnboardingCommitmentView: View {
    var onNext: () -> Void

    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        OnboardingScreenShell(
            title: "How committed are you?",
            subtitle: "Be honest — starting light and staying consistent beats ambitious and quitting.",
            onContinue: onNext
        ) {
            VStack(spacing: 14) {
                ForEach(CommitmentLevel.allCases, id: \.rawValue) { level in
                    CommitmentCard(
                        level: level,
                        isSelected: vm.commitmentLevel == level.rawValue
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.commitmentLevel = level.rawValue
                        }
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }
                    .slideIn(delay: Double(level.rawValue - 1) * 0.07)
                }

                // Visual intensity preview
                IntensityBarsView(level: vm.commitmentLevelEnum)
                    .padding(.top, 8)
                    .slideIn(delay: 0.25)
            }
        }
    }
}

// MARK: - Commitment Card
private struct CommitmentCard: View {
    let level: CommitmentLevel
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        switch level {
        case .light:    return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .moderate: return Color.appPrimary
        case .allIn:    return Color(red: 1.0, green: 0.6, blue: 0.3)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Level indicator dots
                VStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i < level.barCount ? accentColor : Color.appSecondary)
                            .frame(width: 8, height: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.appForeground : Color.appMuted)
                    Text(level.description)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appMuted)
                        .lineLimit(2)
                }

                Spacer()

                // Radio circle
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? accentColor : Color.appBorder,
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 13, height: 13)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor.opacity(0.07) : Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? accentColor.opacity(0.5) : Color.appBorder.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: isSelected ? accentColor.opacity(0.2) : .clear,
                radius: 10
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Intensity Bars View
// Animated bar chart showing the visual "intensity" of the chosen commitment level.
// Each bar grows from the bottom using an animation triggered on level change.
private struct IntensityBarsView: View {
    let level: CommitmentLevel

    @State private var animated = false

    // Number of bars and their relative target heights per level
    private var barHeights: [CGFloat] {
        switch level {
        case .light:    return [0.30, 0.45, 0.35, 0.50, 0.40, 0.30, 0.45]
        case .moderate: return [0.45, 0.60, 0.55, 0.75, 0.65, 0.55, 0.60]
        case .allIn:    return [0.70, 0.85, 0.80, 1.00, 0.90, 0.80, 0.88]
        }
    }

    private var barColor: Color {
        switch level {
        case .light:    return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .moderate: return Color.appPrimary
        case .allIn:    return Color(red: 1.0, green: 0.6, blue: 0.3)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Your daily momentum")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.appMuted)

            GeometryReader { geo in
                let barWidth: CGFloat = (geo.size.width - CGFloat(barHeights.count - 1) * 8) / CGFloat(barHeights.count)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(barHeights.enumerated()), id: \.offset) { idx, targetHeight in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [barColor.opacity(0.5), barColor],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(
                                    width: barWidth,
                                    height: animated ? geo.size.height * targetHeight : 4
                                )
                        }
                    }
                }
            }
            .frame(height: 80)
        }
        .padding(16)
        .glassCard()
        .onAppear { triggerAnimation() }
        .onChange(of: level) { _, _ in
            animated = false
            triggerAnimation()
        }
    }

    private func triggerAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            animated = true
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingCommitmentView(onNext: {})
            .environment({
                let vm = OnboardingViewModel()
                vm.commitmentLevel = 2
                return vm
            }())
    }
    .preferredColorScheme(.dark)
}
