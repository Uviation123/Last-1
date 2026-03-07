import SwiftUI

// MARK: - Screen 4: Personal Identity Reflection
// Two text fields capturing who the user is now and who they want to become.
// An animated arrow transforms between the two states to reinforce the journey.
// Continue requires both fields to have content.
struct OnboardingIdentityView: View {
    var onNext: () -> Void

    @Environment(OnboardingViewModel.self) private var vm
    @FocusState private var focusedField: IdentityField?

    enum IdentityField { case current, desired }

    private var canContinue: Bool {
        !vm.currentIdentity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !vm.desiredIdentity.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingScreenShell(
            title: "Define Your Identity",
            subtitle: "Your identity drives your actions. Let's clarify who you're becoming.",
            isContinueEnabled: canContinue,
            onContinue: {
                focusedField = nil
                onNext()
            }
        ) {
            VStack(spacing: 20) {
                // Current identity card
                IdentityCard(
                    label: "I currently am…",
                    placeholder: "Someone who struggles with consistency",
                    icon: "person.fill",
                    iconColor: Color.appMuted,
                    borderColor: focusedField == .current ? Color.appPrimary.opacity(0.6) : Color.appBorder.opacity(0.4),
                    text: $vm.currentIdentity,
                    isFocused: focusedField == .current
                )
                .focused($focusedField, equals: .current)
                .slideIn(delay: 0.05)

                // Transformation arrow
                TransformArrow(
                    activated: !vm.currentIdentity.isEmpty && !vm.desiredIdentity.isEmpty
                )

                // Desired identity card
                IdentityCard(
                    label: "I want to become…",
                    placeholder: "Someone who shows up every single day",
                    icon: "star.fill",
                    iconColor: Color.appPrimary,
                    borderColor: focusedField == .desired ? Color.appPrimary.opacity(0.8) : Color.appBorder.opacity(0.4),
                    text: $vm.desiredIdentity,
                    isFocused: focusedField == .desired
                )
                .focused($focusedField, equals: .desired)
                .slideIn(delay: 0.1)

                if canContinue {
                    affirmationText
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .slideIn(delay: 0.0)
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    private var affirmationText: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13))
                .foregroundStyle(Color.appPrimary)
            Text("Your transformation starts with today's 1%.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appMuted)
        }
        .padding(.top, 4)
    }
}

// MARK: - Identity Card
private struct IdentityCard: View {
    let label: String
    let placeholder: String
    let icon: String
    let iconColor: Color
    let borderColor: Color
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.appMuted)
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(Color.appForeground)
                .lineLimit(2...4)
                .tint(Color.appPrimary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isFocused ? Color.appCard.opacity(1.0) : Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Transform Arrow
// Animates from a muted dashed downward arrow to a glowing primary-colored arrow
// once both identity fields have content, visualizing the user's transformation journey.
private struct TransformArrow: View {
    let activated: Bool

    @State private var arrowBounce = false

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(activated ? Color.appPrimary.opacity(0.3) : Color.appBorder.opacity(0.3))
                .frame(height: 1)

            VStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(activated ? Color.appPrimary : Color.appMuted.opacity(0.5))
                    .scaleEffect(activated && arrowBounce ? 1.15 : 1.0)
                    .shadow(color: activated ? Color.appPrimary.opacity(0.6) : .clear, radius: 6)

                if activated {
                    Text("Your journey")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.appPrimary.opacity(0.7))
                        .transition(.opacity)
                }
            }

            Rectangle()
                .fill(activated ? Color.appPrimary.opacity(0.3) : Color.appBorder.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.35), value: activated)
        .onChange(of: activated) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).repeatCount(2)) {
                    arrowBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    arrowBounce = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingIdentityView(onNext: {})
            .environment({
                let vm = OnboardingViewModel()
                vm.currentIdentity = "Someone who gives up after a week"
                vm.desiredIdentity = "Someone who shows up every single day"
                return vm
            }())
    }
    .preferredColorScheme(.dark)
}
