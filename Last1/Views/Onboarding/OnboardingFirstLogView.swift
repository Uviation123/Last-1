import SwiftUI
import PhotosUI

// MARK: - Screen 7: First Daily Log Entry
// Guided tutorial for logging the first 1% action. The full log UI mirrors the
// main app's AddLogView so users arrive in the main app already familiar.
// On save: persists a PendingLogData to UserDefaults for HomeViewModel to sync
// after authentication, then plays a celebration animation before advancing.
struct OnboardingFirstLogView: View {
    var onNext: () -> Void

    @Environment(OnboardingViewModel.self) private var vm

    @State private var photosItem: PhotosPickerItem?
    @State private var showCelebration = false
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationOpacity: Double = 0

    var body: some View {
        @Bindable var vm = vm

        ZStack {
            if showCelebration {
                celebrationOverlay
                    .ignoresSafeArea()
                    .zIndex(10)
            }

            OnboardingScreenShell(
                title: "Log Your First 1%",
                subtitle: "What's one thing you did (or will do) today to improve by 1%?",
                continueTitle: vm.firstLogCompleted ? "Awesome! Continue" : "Save My First Log",
                isContinueEnabled: true,
                onContinue: {
                    if vm.firstLogCompleted {
                        onNext()
                    } else {
                        saveLog()
                    }
                }
            ) {
                VStack(spacing: 20) {
                    // Category selection
                    categorySection(vm: vm)
                        .slideIn(delay: 0.05)

                    // Effort slider
                    effortSection(vm: vm)
                        .slideIn(delay: 0.1)

                    // Note field
                    noteSection(vm: vm)
                        .slideIn(delay: 0.15)

                    // Photo picker
                    photoSection(vm: vm)
                        .slideIn(delay: 0.2)
                }
            }
        }
        .onChange(of: photosItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    vm.firstLogImage = image
                }
            }
        }
    }

    // MARK: Category Section

    private func categorySection(vm: OnboardingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .sectionLabel()

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                spacing: 10
            ) {
                ForEach(LogCategory.allCases) { category in
                    CategoryTile(
                        category: category,
                        isSelected: vm.firstLogCategory == category
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            vm.firstLogCategory = category
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            }
        }
    }

    // MARK: Effort Section

    private func effortSection(vm: OnboardingViewModel) -> some View {
        @Bindable var vm = vm

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Effort Level")
                    .sectionLabel()
                Spacer()
                Text(effortLabel(for: vm.firstLogEffort))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
            }

            Slider(value: $vm.firstLogEffort, in: 1...5, step: 1)
                .tint(Color.appPrimary)

            // Visual effort dots
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(Double(level) <= vm.firstLogEffort ? Color.appPrimary : Color.appSecondary)
                        .frame(width: 10, height: 10)
                        .scaleEffect(Double(level) == vm.firstLogEffort.rounded() ? 1.3 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: vm.firstLogEffort)
                    if level < 5 { Spacer() }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func effortLabel(for value: Double) -> String {
        switch Int(value.rounded()) {
        case 1: return "Very Light"
        case 2: return "Light"
        case 3: return "Moderate"
        case 4: return "Hard"
        default: return "Maximum"
        }
    }

    // MARK: Note Section

    private func noteSection(vm: OnboardingViewModel) -> some View {
        @Bindable var vm = vm

        return VStack(alignment: .leading, spacing: 10) {
            Text("Note (optional)")
                .sectionLabel()

            TextField("What did you do? How did it feel?", text: $vm.firstLogNote, axis: .vertical)
                .font(.system(size: 14))
                .foregroundStyle(Color.appForeground)
                .lineLimit(3...5)
                .tint(Color.appPrimary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.appBorder.opacity(0.4), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: Photo Section

    private func photoSection(vm: OnboardingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photo (optional)")
                .sectionLabel()

            if let image = vm.firstLogImage {
                // Show selected photo with remove button
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        withAnimation { vm.firstLogImage = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.appForeground)
                            .background(Color.appBackground.clipShape(Circle()))
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: $photosItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appMuted)
                        Text("Add a photo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        Color.appBorder.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Save Logic

    private func saveLog() {
        vm.savePendingFirstLog()

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCelebration = true
            celebrationScale = 1.0
            celebrationOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                celebrationOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showCelebration = false
            }
        }
    }

    // MARK: Celebration Overlay

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)

            VStack(spacing: 20) {
                // Pulsing ring
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        PulsingRing(delay: Double(i) * 0.3)
                    }
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.appPrimary)
                    }
                }

                VStack(spacing: 8) {
                    Text("First 1% Logged!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.appForeground)
                    Text("You've started your momentum. Keep going.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
        }
    }
}

// MARK: - Category Tile
private struct CategoryTile: View {
    let category: LogCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? category.chartColor.opacity(0.2) : Color.appSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? category.chartColor : Color.appMuted)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? category.chartColor.opacity(0.7) : Color.clear,
                            lineWidth: 1.5
                        )
                )

                Text(category.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? category.chartColor : Color.appMuted)
                    .lineLimit(1)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? category.chartColor.opacity(0.3) : .clear, radius: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pulsing Ring
private struct PulsingRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.7

    var body: some View {
        Circle()
            .strokeBorder(Color.appPrimary.opacity(opacity), lineWidth: 1.5)
            .frame(width: 90, height: 90)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.2)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
                ) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingFirstLogView(onNext: {})
            .environment(OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
