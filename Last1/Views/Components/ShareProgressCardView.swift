import SwiftUI

// MARK: - Card Dimensions

private let cardWidth:  CGFloat = 390
private let cardHeight: CGFloat = 693

// MARK: - Always-dark card palette (never adapts to system colour scheme)

private extension Color {
    static let cardBgTop    = Color(red: 0.039, green: 0.039, blue: 0.039)   // #0a0a0a
    static let cardBgBottom = Color(red: 0.059, green: 0.102, blue: 0.071)   // #0f1a12
    static let cardMint     = Color(red: 0.208, green: 0.851, blue: 0.627)
    static let cardFg       = Color(red: 0.965, green: 0.965, blue: 0.965)
    static let cardMuted    = Color(white: 0.60)
    static let cardSurface  = Color(red: 0.11, green: 0.113, blue: 0.165)
    static let cardBorder   = Color(red: 0.196, green: 0.20, blue: 0.267)
}

// MARK: - ProgressShareCard

/// The shareable card itself. Always renders in dark mode regardless of system setting.
struct ProgressShareCard: View {
    let stats: UserStats
    var showWatermark: Bool = true

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.cardBgTop, .cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                heroSection
                    .padding(.top, 28)

                statsRow
                    .padding(.horizontal, 24)
                    .padding(.top, 26)

                momentumBar
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                identityQuote
                    .padding(.horizontal, 28)
                    .padding(.top, 22)

                categoryBadge
                    .padding(.top, 18)

                Spacer(minLength: 0)

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        // Force dark environment so any nested dynamic colours resolve correctly
        .environment(\.colorScheme, .dark)
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                // Stylised app icon mark
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.cardMint.opacity(0.14))
                        .frame(width: 34, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(Color.cardMint.opacity(0.28), lineWidth: 1)
                        )
                    Text("1%")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color.cardMint)
                }
                Text("Last 1%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.cardFg)
            }

            Spacer()

            Text(formattedDate)
                .font(.system(size: 11))
                .foregroundStyle(Color.cardMuted)
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        ZStack {
            // Soft glow halo behind the number
            Circle()
                .fill(Color.cardMint.opacity(0.11))
                .frame(width: 170, height: 170)
                .blur(radius: 48)

            VStack(spacing: 6) {
                Text("\(stats.currentStreak)")
                    .font(.system(size: 86, weight: .black))
                    .foregroundStyle(Color.cardMint)
                    .shadow(color: Color.cardMint.opacity(0.45), radius: 22, x: 0, y: 0)

                Text("day streak")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(3.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.cardFg.opacity(0.60))
            }
        }
    }

    // MARK: Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(stats.totalLogs)", label: "Total Logs")

            Rectangle()
                .fill(Color.cardBorder.opacity(0.5))
                .frame(width: 1, height: 34)

            statColumn(value: "\(stats.longestStreak)", label: "Best Streak")
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardSurface.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.cardBorder.opacity(0.45), lineWidth: 1)
                )
        )
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color.cardFg)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.9)
                .foregroundStyle(Color.cardMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Momentum Bar

    private var momentumBar: some View {
        VStack(spacing: 7) {
            HStack {
                Text("Momentum")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Color.cardMuted)
                Spacer()
                Text("\(Int(stats.momentumScore))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.cardMint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.cardSurface)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.cardMint.opacity(0.75), Color.cardMint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (stats.momentumScore / 100))
                        .shadow(color: Color.cardMint.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: Identity Quote

    private var identityQuote: some View {
        Text("\u{201C}\(stats.identityStatement)\u{201D}")
            .font(.system(size: 14, weight: .regular).italic())
            .foregroundStyle(Color.cardFg.opacity(0.70))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Category Badge

    private var categoryBadge: some View {
        VStack(spacing: 7) {
            Text("Most Logged")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.cardMuted)

            Text(stats.topCategory)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.cardMint)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.cardMint.opacity(0.10))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.cardMint.opacity(0.28), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 8) {
            Text(motivationalLine)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.cardFg.opacity(0.50))
                .multilineTextAlignment(.center)

            if showWatermark {
                Text("last1percent.app")
                    .font(.system(size: 10))
                    .tracking(0.6)
                    .foregroundStyle(Color.cardMuted.opacity(0.40))
            }
        }
    }

    // MARK: Helpers

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: Date())
    }

    private var motivationalLine: String {
        switch stats.currentStreak {
        case 100...: return "You are the last 1%."
        case 30...:  return "You've built something real."
        case 7...:   return "One week. You're ahead of most."
        case 3...:   return "The habit is forming."
        default:     return "Tiny gains. Massive results."
        }
    }
}

// MARK: - ImageRenderer Snapshot Helper

extension View {
    /// Renders the view into a UIImage using ImageRenderer (iOS 16+).
    /// Always uses scale 3 for crisp exports regardless of device screen density.
    @MainActor
    func shareCardSnapshot() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.proposedSize = .init(width: cardWidth, height: cardHeight)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

// MARK: - System Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - Share Progress Preview Sheet

/// Full-screen modal that shows the card preview and Share / Save to Photos actions.
struct ShareProgressPreviewSheet: View {
    let stats: UserStats
    var showWatermark: Bool = true

    @Environment(\.dismiss) private var dismiss

    @State private var cardScale: CGFloat = 0.82
    @State private var cardOpacity: Double = 0
    @State private var showSystemShare = false
    @State private var cardImage: UIImage?
    @State private var savedFeedback = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 18)
                }

                Spacer()

                // Card preview
                ProgressShareCard(stats: stats, showWatermark: showWatermark)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.55), radius: 32, y: 12)
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)

                Spacer()

                // Action buttons
                VStack(spacing: 10) {
                    // Save to Photos
                    Button { saveToPhotos() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: savedFeedback ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.system(size: 15, weight: .semibold))
                            Text(savedFeedback ? "Saved to Photos!" : "Save to Photos")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.10))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.208, green: 0.851, blue: 0.627))
                                .shadow(
                                    color: Color(red: 0.208, green: 0.851, blue: 0.627).opacity(0.40),
                                    radius: 14, y: 4
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(savedFeedback)
                    .animation(.easeInOut(duration: 0.2), value: savedFeedback)

                    // Share via system sheet
                    Button { showSystemShare = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Share")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.11, green: 0.113, blue: 0.165))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(
                                            Color(red: 0.196, green: 0.20, blue: 0.267),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
        .onAppear {
            // Animate card in
            withAnimation(.spring(response: 0.52, dampingFraction: 0.78).delay(0.08)) {
                cardScale = 0.875
                cardOpacity = 1
            }
            // Pre-render image off the main run loop so it doesn't block the animation
            Task { @MainActor in
                cardImage = ProgressShareCard(stats: stats, showWatermark: showWatermark)
                    .shareCardSnapshot()
            }
        }
        .sheet(isPresented: $showSystemShare) {
            if let image = cardImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: Save to Photos

    private func saveToPhotos() {
        let image = cardImage
            ?? ProgressShareCard(stats: stats, showWatermark: showWatermark).shareCardSnapshot()
        guard let image else { return }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        withAnimation(.easeInOut(duration: 0.25)) { savedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.25)) { savedFeedback = false }
        }
    }
}

// MARK: - Convenience Share Button

/// Drop-in share button that can be placed in any navigation bar or toolbar.
struct ShareProgressButton: View {
    let stats: UserStats
    var showWatermark: Bool = true
    @State private var showPreview = false

    var body: some View {
        Button {
            showPreview = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .medium))
        }
        .sheet(isPresented: $showPreview) {
            ShareProgressPreviewSheet(stats: stats, showWatermark: showWatermark)
                .presentationBackground(.clear)
                .presentationDetents([.large])
        }
    }
}

// MARK: - Preview

#Preview("Card") {
    let sample = UserStats(
        currentStreak: 30,
        longestStreak: 42,
        totalLogs: 87,
        momentumScore: 78,
        topCategory: "Fitness",
        identityStatement: "I am someone who shows up every day.",
        weeklyLogCount: 6
    )
    return ProgressShareCard(stats: sample, showWatermark: true)
        .frame(width: cardWidth, height: cardHeight)
}

#Preview("Preview Sheet") {
    let sample = UserStats(
        currentStreak: 7,
        longestStreak: 14,
        totalLogs: 23,
        momentumScore: 55,
        topCategory: "Learning",
        identityStatement: "I grow 1% better every single day.",
        weeklyLogCount: 5
    )
    return ShareProgressPreviewSheet(stats: sample, showWatermark: true)
}
