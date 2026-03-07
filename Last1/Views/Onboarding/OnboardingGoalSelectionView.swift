import SwiftUI

// MARK: - Screen 2: Goal Selection
// Multi-select chip grid showing 9 predefined goal categories.
// Selections are written to OnboardingViewModel.selectedGoals.
// Continue is disabled until at least one goal is selected.
struct OnboardingGoalSelectionView: View {
    var onNext: () -> Void

    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        OnboardingScreenShell(
            title: "What do you want to improve?",
            subtitle: "Pick the areas that matter most to you. You can add more later.",
            continueTitle: "Let's Go",
            isContinueEnabled: !vm.selectedGoals.isEmpty,
            onContinue: onNext
        ) {
            OnboardingFlowLayout(spacing: 10) {
                ForEach(OnboardingGoal.all) { goal in
                    GoalChip(
                        goal: goal,
                        isSelected: vm.selectedGoals.contains(goal.id)
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                            if vm.selectedGoals.contains(goal.id) {
                                vm.selectedGoals.remove(goal.id)
                            } else {
                                vm.selectedGoals.insert(goal.id)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 8)

            if !vm.selectedGoals.isEmpty {
                selectionSummary
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var selectionSummary: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.appPrimary)
            Text("\(vm.selectedGoals.count) area\(vm.selectedGoals.count == 1 ? "" : "s") selected")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appMuted)
        }
        .padding(.top, 4)
    }
}

// MARK: - Goal Chip
private struct GoalChip: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? goal.color.opacity(0.25) : Color.appSecondary)
                        .frame(width: 32, height: 32)
                    Image(systemName: goal.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected ? goal.color : Color.appMuted)
                }

                Text(goal.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Color.appForeground : Color.appMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? goal.color.opacity(0.12) : Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? goal.color.opacity(0.6) : Color.appBorder.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? goal.color.opacity(0.25) : .clear,
                radius: 8
            )
            .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeIn(duration: 0.1)) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
                }
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingGoalSelectionView(onNext: {})
            .environment(OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
