import SwiftUI

// MARK: - Screen 3: Pain Point Identification
// Multi-select chips for the 8 common struggle areas.
// Helps personalize coaching copy shown later in the flow.
// Continue is always enabled (pain point selection is optional).
struct OnboardingPainPointView: View {
    var onNext: () -> Void

    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        OnboardingScreenShell(
            title: "What holds you back?",
            subtitle: "Identifying your struggles helps us show you what to focus on first.",
            continueTitle: vm.selectedPainPoints.isEmpty ? "Skip for Now" : "Continue",
            onContinue: onNext
        ) {
            VStack(spacing: 10) {
                ForEach(OnboardingPainPoint.all) { point in
                    PainPointRow(
                        point: point,
                        isSelected: vm.selectedPainPoints.contains(point.id)
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                            if vm.selectedPainPoints.contains(point.id) {
                                vm.selectedPainPoints.remove(point.id)
                            } else {
                                vm.selectedPainPoints.insert(point.id)
                            }
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                    .slideIn(delay: Double(OnboardingPainPoint.all.firstIndex(where: { $0.id == point.id }) ?? 0) * 0.04)
                }
            }
        }
    }
}

// MARK: - Pain Point Row
// Full-width selectable row with icon, label and checkbox-style toggle.
private struct PainPointRow: View {
    let point: OnboardingPainPoint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.appPrimary.opacity(0.15) : Color.appSecondary)
                        .frame(width: 38, height: 38)
                    Image(systemName: point.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? Color.appPrimary : Color.appMuted)
                }

                // Label
                Text(point.label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? Color.appForeground : Color.appMuted)

                Spacer()

                // Checkmark toggle
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.appPrimary : Color.appBorder,
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.appPrimary.opacity(0.06) : Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? Color.appPrimary.opacity(0.4) : Color.appBorder.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingPainPointView(onNext: {})
            .environment(OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
