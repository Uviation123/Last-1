import SwiftUI

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color Tokens
// Translated from v0 globals.css oklch values

extension Color {
    // Backgrounds
    static let appBackground = Color(red: 0.053, green: 0.055, blue: 0.086)
    static let appCard = Color(red: 0.11, green: 0.113, blue: 0.165)
    static let appSecondary = Color(red: 0.165, green: 0.168, blue: 0.235)
    static let appBorder = Color(red: 0.196, green: 0.2, blue: 0.267)

    // Glass surface (used in GlassCard)
    static let glassFill = Color(red: 0.125, green: 0.129, blue: 0.18)
    static let glassBorder = Color(red: 0.235, green: 0.239, blue: 0.322)

    // Text
    static let appForeground = Color(red: 0.965, green: 0.965, blue: 0.965)
    static let appMuted = Color(red: 0.6, green: 0.6, blue: 0.6)

    // Primary: oklch(0.72 0.19 160) — mint-teal green
    static let appPrimary = Color(red: 0.208, green: 0.851, blue: 0.627)

    // Destructive
    static let appDestructive = Color(red: 0.9, green: 0.3, blue: 0.3)

    // Chart / Category colors
    static let chart1 = Color.appPrimary                                    // Mind — mint green
    static let chart2 = Color(red: 0.478, green: 0.506, blue: 1.0)        // Body — blue/indigo
    static let chart3 = Color(red: 0.953, green: 0.651, blue: 0.137)      // Skills — amber
    static let chart4 = Color(red: 0.863, green: 0.475, blue: 0.627)      // Heart — pink/rose
    static let chart5 = Color(red: 0.667, green: 0.867, blue: 0.4)        // misc — yellow-green

    // Glow helper (primary at low opacity, used for ambient effects)
    static let appGlow = Color.appPrimary.opacity(0.15)
}

// MARK: - Dynamic Color Tokens (Light/Dark aware)

extension Color {
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appBackground : Color(hex: "f5f5f7")
    }
    static func appSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appCard : Color(hex: "ffffff")
    }
    static func appSurfaceSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appSecondary : Color(hex: "f0f0f2")
    }
    static func appPrimaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appForeground : Color(hex: "0a0a0a")
    }
    static func appSecondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)
    }
    static func appMutedText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appMuted : .black.opacity(0.35)
    }
    static func appFieldBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appSecondary : Color(hex: "ffffff")
    }
    static func appBorderDynamic(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appBorder : .black.opacity(0.08)
    }
    static func appAccent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .appPrimary : Color(hex: "1db864")
    }
    static func appTabBar(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.059, green: 0.059, blue: 0.059) : Color(hex: "ffffff")
    }
    /// Contrast text label on primary-green filled buttons
    static func appButtonLabel(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.05, green: 0.2, blue: 0.12) : Color(hex: "ffffff")
    }
    static func appGlassFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .glassFill : Color(hex: "ffffff")
    }
    static func appGlassBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .glassBorder : .black.opacity(0.08)
    }
}

// MARK: - GlassCard Modifier

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.glassFill.opacity(0.6))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.glassBorder.opacity(0.3), lineWidth: 1)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
}

// MARK: - Section Label Style

struct SectionLabelStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Color.appMutedText(colorScheme))
    }
}

extension View {
    func sectionLabel() -> some View {
        self.modifier(SectionLabelStyle())
    }
}

// MARK: - Animated Progress Bar

struct AppProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 6

    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appSurfaceSecondary(colorScheme))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(max(progress, 0), 1)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
}

// MARK: - Ambient Glow

struct AmbientGlow: View {
    var color: Color = .appPrimary
    var size: CGFloat = 160

    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color.opacity(pulsing ? 0.12 : 0.07))
            .frame(width: size, height: size)
            .blur(radius: 40)
            .scaleEffect(pulsing ? 1.1 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4).repeatForever(autoreverses: true)
                ) {
                    pulsing = true
                }
            }
    }
}

// MARK: - Card Entry Animation

struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(delay: delay))
    }
}
