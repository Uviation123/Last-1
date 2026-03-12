import SwiftUI

// MARK: - Onboarding Container
// Coordinates navigation across the 8-screen onboarding flow.
// Preserves the existing `onComplete: () -> Void` signature used in Last1App.swift.
// The shared OnboardingViewModel is injected into the environment so all child screens
// can read and write onboarding state without explicit prop-drilling.
struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentScreen = 0
    @State private var vm = OnboardingViewModel()

    // Total number of screens in the flow
    private let totalScreens = 8

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color.appBackground(colorScheme).ignoresSafeArea()

            // Ambient background glow that persists across screens
            AmbientGlow(color: .appPrimary, size: 300)
                .offset(y: -200)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                screenContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(vm)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalScreens, id: \.self) { i in
                Capsule()
                    .fill(progressColor(for: i))
                    .frame(height: 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentScreen)
            }
        }
    }

    private func progressColor(for index: Int) -> Color {
        if index < currentScreen {
            return Color.appAccent(colorScheme).opacity(0.5)
        } else if index == currentScreen {
            return Color.appAccent(colorScheme)
        } else {
            return Color.appMutedText(colorScheme)
        }
    }

    // MARK: - Screen Routing
    // Each screen receives advance/retreat closures rather than a binding to currentScreen,
    // keeping each view decoupled from the navigation index.

    @ViewBuilder
    private var screenContent: some View {
        switch currentScreen {
        case 0:
            OnboardingWelcomeView(onNext: advance)
                .transition(screenTransition)
        case 1:
            OnboardingGoalSelectionView(onNext: advance)
                .transition(screenTransition)
        case 2:
            OnboardingPainPointView(onNext: advance)
                .transition(screenTransition)
        case 3:
            OnboardingIdentityView(onNext: advance)
                .transition(screenTransition)
        case 4:
            OnboardingCommitmentView(onNext: advance)
                .transition(screenTransition)
        case 5:
            OnboardingGrowthResultView(onNext: advance)
                .transition(screenTransition)
        case 6:
            OnboardingFirstLogView(onNext: advance)
                .transition(screenTransition)
        case 7:
            OnboardingPaywallView(onComplete: onComplete)
                .transition(screenTransition)
        default:
            EmptyView()
        }
    }

    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            if currentScreen < totalScreens - 1 {
                currentScreen += 1
            } else {
                onComplete()
            }
        }
    }
}

// MARK: - FlowLayout
// Wrapping chip grid used by goal and pain-point screens.
// Kept here so it's accessible to all Onboarding sub-views in the same module.
struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > width && rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Onboarding Continue Button
// Shared bottom CTA button used across multiple screens.
struct OnboardingContinueButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    init(_ title: String = "Continue", isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.appButtonLabel(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? Color.appAccent(colorScheme) : Color.appSurfaceSecondary(colorScheme))
                    .shadow(
                        color: isEnabled ? Color.appAccent(colorScheme).opacity(0.35) : .clear,
                        radius: 14,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Onboarding Screen Shell
// Shared layout wrapper providing consistent top heading + scrollable body + bottom CTA.
struct OnboardingScreenShell<Content: View>: View {
    let title: String
    let subtitle: String
    let content: () -> Content
    let continueTitle: String
    let isContinueEnabled: Bool
    let onContinue: () -> Void

    @Environment(\.colorScheme) var colorScheme

    init(
        title: String,
        subtitle: String,
        continueTitle: String = "Continue",
        isContinueEnabled: Bool = true,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.continueTitle = continueTitle
        self.isContinueEnabled = isContinueEnabled
        self.onContinue = onContinue
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .slideIn(delay: 0.05)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appMutedText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .slideIn(delay: 0.1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)

            // Scrollable body
            ScrollView(showsIndicators: false) {
                content()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Bottom CTA
            OnboardingContinueButton(
                continueTitle,
                isEnabled: isContinueEnabled,
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
