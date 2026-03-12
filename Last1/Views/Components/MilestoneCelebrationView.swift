import SwiftUI

// MARK: - Milestone Model

enum Milestone: CaseIterable, Identifiable {
    case day3, day7, day14, day30, day50, day100

    var id: Int { day }

    var day: Int {
        switch self {
        case .day3:   return 3
        case .day7:   return 7
        case .day14:  return 14
        case .day30:  return 30
        case .day50:  return 50
        case .day100: return 100
        }
    }

    var title: String { "Day \(day)" }

    var message: String {
        switch self {
        case .day3:   return "3 days in. The habit is forming."
        case .day7:   return "One week. You're already in the top 50%."
        case .day14:  return "Two weeks straight. This is becoming who you are."
        case .day30:  return "30 days. You've built something real."
        case .day50:  return "50 days. Most people quit by now. You didn't."
        case .day100: return "100 days. You are the last 1%."
        }
    }

    var icon: String {
        switch self {
        case .day3:   return "bolt.fill"
        case .day7:   return "flame.fill"
        case .day14:  return "star.fill"
        case .day30:  return "trophy.fill"
        case .day50:  return "medal.fill"
        case .day100: return "crown.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .day3:   return .chart3
        case .day7:   return .chart3
        case .day14:  return Color(red: 0.953, green: 0.851, blue: 0.4)
        case .day30:  return .appPrimary
        case .day50:  return .chart2
        case .day100: return Color(red: 1.0, green: 0.82, blue: 0.3)
        }
    }

    static func milestone(for streak: Int) -> Milestone? {
        allCases.first { $0.day == streak }
    }

    private static let keyPrefix = "milestone_shown_day_"

    var hasBeenShown: Bool {
        UserDefaults.standard.bool(forKey: "\(Milestone.keyPrefix)\(day)")
    }

    func markAsShown() {
        UserDefaults.standard.set(true, forKey: "\(Milestone.keyPrefix)\(day)")
    }
}

// MARK: - Confetti Particle Data

private struct ConfettiParticleData: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotationEnd: Double
    let duration: Double
    let delay: Double
    let isCircle: Bool
}

// MARK: - Individual Confetti Particle View

private struct ConfettiParticleView: View {
    let data: ConfettiParticleData
    let screenHeight: CGFloat

    @State private var yOffset: CGFloat = 0
    @State private var xWobble: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Group {
            if data.isCircle {
                Circle()
                    .fill(data.color)
                    .frame(width: data.width, height: data.width)
            } else {
                Rectangle()
                    .fill(data.color)
                    .frame(width: data.width, height: data.height)
            }
        }
        .rotationEffect(.degrees(rotation))
        .offset(x: xWobble, y: yOffset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: data.duration).delay(data.delay)) {
                yOffset = screenHeight + 100
                rotation = data.rotationEnd
                xWobble = CGFloat.random(in: -40...40)
            }
            withAnimation(.linear(duration: 0.6).delay(data.delay + data.duration - 0.6)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Confetti Canvas View

private struct ConfettiView: View {
    private let particles: [ConfettiParticleData]
    private let screenHeight = UIScreen.main.bounds.height
    private let screenWidth = UIScreen.main.bounds.width

    init() {
        let palette: [Color] = [
            .appPrimary,
            Color(red: 0.478, green: 0.506, blue: 1.0),
            Color(red: 0.953, green: 0.651, blue: 0.137),
            Color(red: 0.863, green: 0.475, blue: 0.627),
            Color(red: 0.667, green: 0.867, blue: 0.4),
            Color(red: 1.0, green: 0.85, blue: 0.3),
            Color.white.opacity(0.9)
        ]
        let total = 90
        var ps: [ConfettiParticleData] = []
        for i in 0..<total {
            let spread = UIScreen.main.bounds.width / CGFloat(total)
            ps.append(ConfettiParticleData(
                id: i,
                color: palette[i % palette.count],
                x: spread * CGFloat(i) + CGFloat.random(in: -16...16),
                width: CGFloat.random(in: 5...10),
                height: CGFloat.random(in: 10...18),
                rotationEnd: Double.random(in: -720...720),
                duration: Double.random(in: 2.2...3.8),
                delay: Double.random(in: 0...1.0),
                isCircle: i % 5 == 0
            ))
        }
        particles = ps
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                ConfettiParticleView(data: p, screenHeight: screenHeight)
                    .position(x: p.x, y: -8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Milestone Celebration View

struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void
    var stats: UserStats? = nil

    @State private var overlayOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.72
    @State private var cardOpacity: Double = 0
    @State private var showConfetti = false
    @State private var glowPulsing = false
    @State private var showSharePreview = false

    var body: some View {
        ZStack {
            // Dimmed overlay
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .opacity(overlayOpacity)
                .onTapGesture { /* block tap-through */ }

            // Confetti rain
            if showConfetti {
                ConfettiView()
            }

            // Celebration card
            VStack(spacing: 0) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(milestone.iconColor.opacity(glowPulsing ? 0.28 : 0.14))
                        .frame(width: 100, height: 100)
                        .blur(radius: 22)
                        .scaleEffect(glowPulsing ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulsing)

                    ZStack {
                        Circle()
                            .fill(milestone.iconColor.opacity(0.18))
                            .frame(width: 76, height: 76)
                            .overlay(
                                Circle()
                                    .strokeBorder(milestone.iconColor.opacity(0.3), lineWidth: 1.5)
                            )

                        Image(systemName: milestone.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(milestone.iconColor)
                            .symbolEffect(.bounce, value: showConfetti)
                    }
                }
                .padding(.bottom, 22)

                // Day label
                Text(milestone.title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3.5)
                    .foregroundStyle(milestone.iconColor)
                    .padding(.bottom, 10)

                // Message
                Text(milestone.message)
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.appForeground)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 32)

                // Share button (only when UserStats are available)
                if stats != nil {
                    Button {
                        showSharePreview = true
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Share This Moment")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(milestone.iconColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(milestone.iconColor.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(milestone.iconColor.opacity(0.28), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
                }

                // Dismiss button
                Button(action: dismiss) {
                    Text("Keep Going →")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.1))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.appPrimary)
                                .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, y: 4)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(red: 0.08, green: 0.082, blue: 0.126))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .strokeBorder(Color.glassBorder.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.55), radius: 50, y: 24)
            )
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            showConfetti = true

            withAnimation(.easeOut(duration: 0.25)) {
                overlayOpacity = 1
            }

            withAnimation(.spring(response: 0.48, dampingFraction: 0.72).delay(0.12)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                glowPulsing = true
            }
        }
        .sheet(isPresented: $showSharePreview) {
            if let stats {
                ShareProgressPreviewSheet(stats: stats, showWatermark: true)
                    .presentationBackground(.clear)
                    .presentationDetents([.large])
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.22)) {
            cardScale = 0.88
            cardOpacity = 0
            overlayOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

#Preview {
    MilestoneCelebrationView(milestone: .day30) {}
        .preferredColorScheme(.dark)
}
