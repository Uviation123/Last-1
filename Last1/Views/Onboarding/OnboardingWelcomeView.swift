import SwiftUI

// MARK: - Screen 1: Welcome
// Introduces the "1% Better Every Day" concept with an animated rising line chart
// and a glowing gradient. No data collection — pure value proposition.
struct OnboardingWelcomeView: View {
    var onNext: () -> Void

    @State private var chartProgress: CGFloat = 0
    @State private var glowPulse = false
    @State private var heroVisible = false
    @State private var badgeVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Chart visual
            chartSection
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

            // Hero copy
            heroSection
                .padding(.horizontal, 28)
                .padding(.bottom, 48)

            // CTA
            OnboardingContinueButton("Get Started", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).delay(0.2)) {
                chartProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                badgeVisible = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                heroVisible = true
            }
        }
    }

    // MARK: Chart Section

    private var chartSection: some View {
        ZStack {
            // Glow beneath the chart
            Ellipse()
                .fill(Color.appPrimary.opacity(glowPulse ? 0.18 : 0.10))
                .frame(height: 40)
                .blur(radius: 24)
                .offset(y: 80)

            VStack(spacing: 12) {
                // "1%" badge
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appPrimary.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: 1)
                        )
                    Text("1%")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(Color.appPrimary)
                }
                .frame(width: 72, height: 72)
                .scaleEffect(badgeVisible ? 1.0 : 0.6)
                .opacity(badgeVisible ? 1.0 : 0)

                // Animated rising line chart
                RisingLineChart(progress: chartProgress)
                    .frame(height: 140)
            }
        }
    }

    // MARK: Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            Text("1% Better.\nEvery Day.")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color.appForeground)
                .multilineTextAlignment(.center)
                .opacity(heroVisible ? 1 : 0)
                .offset(y: heroVisible ? 0 : 18)

            Text("Small daily actions compound into extraordinary change. The Last 1% is where champions are built.")
                .font(.system(size: 15))
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .opacity(heroVisible ? 1 : 0)
                .offset(y: heroVisible ? 0 : 12)

            // Stat pills
            HStack(spacing: 12) {
                StatPill(value: "365", label: "days")
                StatPill(value: "37x", label: "growth")
                StatPill(value: "1%", label: "daily")
            }
            .padding(.top, 8)
            .opacity(heroVisible ? 1 : 0)
            .offset(y: heroVisible ? 0 : 10)
        }
    }
}

// MARK: - Rising Line Chart
// Draws a smooth bezier curve that animates from flat-left to a rising arc.
private struct RisingLineChart: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Grid lines (subtle)
                VStack(spacing: 0) {
                    ForEach(0..<4) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.appBorder.opacity(0.3))
                            .frame(height: 1)
                    }
                }

                // Fill gradient below curve
                chartFillPath(width: w, height: h, progress: progress)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.3), Color.appPrimary.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Curve line
                chartLinePath(width: w, height: h, progress: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.6), Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                // Glowing end dot
                if progress > 0.05 {
                    let endPt = curveEndPoint(width: w, height: h, progress: progress)
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 10, height: 10)
                        .shadow(color: Color.appPrimary.opacity(0.8), radius: 6)
                        .position(endPt)
                }
            }
        }
    }

    // Cubic bezier that starts flat and rises steeply at the end
    private func curvePoints(width: CGFloat, height: CGFloat, progress: CGFloat) -> [CGPoint] {
        let clipped = min(max(progress, 0), 1)
        let endX = width * clipped
        let startY = height * 0.85
        let endY = height * (0.85 - 0.70 * clipped)
        let cp1 = CGPoint(x: endX * 0.4, y: startY)
        let cp2 = CGPoint(x: endX * 0.7, y: endY + (startY - endY) * 0.5)
        return [
            CGPoint(x: 0, y: startY),
            cp1,
            cp2,
            CGPoint(x: endX, y: endY)
        ]
    }

    private func chartLinePath(width: CGFloat, height: CGFloat, progress: CGFloat) -> Path {
        let pts = curvePoints(width: width, height: height, progress: progress)
        var path = Path()
        path.move(to: pts[0])
        path.addCurve(to: pts[3], control1: pts[1], control2: pts[2])
        return path
    }

    private func chartFillPath(width: CGFloat, height: CGFloat, progress: CGFloat) -> Path {
        let pts = curvePoints(width: width, height: height, progress: progress)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: pts[0])
        path.addCurve(to: pts[3], control1: pts[1], control2: pts[2])
        path.addLine(to: CGPoint(x: pts[3].x, y: height))
        path.closeSubpath()
        return path
    }

    private func curveEndPoint(width: CGFloat, height: CGFloat, progress: CGFloat) -> CGPoint {
        let pts = curvePoints(width: width, height: height, progress: progress)
        return pts[3]
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.appPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.appMuted)
                .tracking(0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.appBorder.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardingWelcomeView(onNext: {})
    }
    .preferredColorScheme(.dark)
}
