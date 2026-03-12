import SwiftUI
import StoreKit

// MARK: - Screen 8: Paywall
// Presents the 7-day free trial offer with a benefits checklist.
// "Start Free Trial" triggers a real StoreKit 2 purchase; on success onComplete is called.
// "Continue for Free" bypasses the subscription and proceeds to the main app.
struct OnboardingPaywallView: View {
    var onComplete: () -> Void

    @Environment(SubscriptionViewModel.self) private var subVM
    @Environment(\.colorScheme) private var colorScheme

    @State private var featuresVisible = false
    @State private var ctaVisible = false
    @State private var glowPulse = false

    private var features: [PaywallFeature] {
        [
            PaywallFeature(icon: "tray.full.fill",        color: .blue,    title: "Unlimited Log History",      description: "Access every entry you've ever logged"),
            PaywallFeature(icon: "bolt.fill",             color: .orange,  title: "Effort Rating on Logs",      description: "Track how hard you pushed each session"),
            PaywallFeature(icon: "chart.bar.fill",        color: .purple,  title: "30 & 90 Day Growth Charts",  description: "See your long-term progress at a glance"),
            PaywallFeature(icon: "bell.badge.fill",       color: .yellow,  title: "Daily Reminders",            description: "Never miss a day with timely check-in nudges"),
            PaywallFeature(icon: "wand.and.stars",        color: Color.appAccent(colorScheme), title: "Motivational Nudges", description: "Personalised messages to keep you going"),
            PaywallFeature(icon: "flame.fill",            color: .red,     title: "Streak at Risk Alerts",      description: "Get warned before your streak breaks"),
            PaywallFeature(icon: "exclamationmark.triangle.fill", color: .pink, title: "Broken Streak Alerts", description: "Know instantly when a streak has ended"),
        ]
    }

    var body: some View {
        ZStack {
            Color.appBackground(colorScheme).ignoresSafeArea()

            // Top glow
            AmbientGlow(color: .appPrimary, size: 280)
                .offset(y: -260)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                    trialBadge
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    featuresSection
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    ctaSection
                        .padding(.top, 28)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                featuresVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                ctaVisible = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            Task { await subVM.loadProduct() }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Unlock Your Full\nPotential")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(Color.appPrimaryText(colorScheme))
                .multilineTextAlignment(.center)
                .slideIn(delay: 0.05)

            Text("Join thousands building unstoppable momentum with Last 1% Pro.")
                .font(.system(size: 15))
                .foregroundStyle(Color.appMutedText(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .slideIn(delay: 0.1)
        }
    }

    // MARK: Trial Badge

    private var trialBadge: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent(colorScheme).opacity(0.2), Color.appAccent(colorScheme).opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.appAccent(colorScheme).opacity(0.6), Color.appAccent(colorScheme).opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.appAccent(colorScheme).opacity(glowPulse ? 0.25 : 0.10), radius: 20)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.appAccent(colorScheme))
                            Text("7-Day Free Trial")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.appPrimaryText(colorScheme))
                        }
                        Text("Then $4.99/month — cancel anytime")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("FREE")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Color.appAccent(colorScheme))
                        Text("7 days")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    }
                }
                .padding(20)
            }
        }
        .slideIn(delay: 0.15)
    }

    // MARK: Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you get")
                .sectionLabel()
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                ForEach(Array(features.enumerated()), id: \.element.title) { idx, feature in
                    FeatureRow(feature: feature)
                        .opacity(featuresVisible ? 1 : 0)
                        .offset(y: featuresVisible ? 0 : 12)
                        .animation(
                            .easeOut(duration: 0.4).delay(Double(idx) * 0.06),
                            value: featuresVisible
                        )
                }
            }
        }
    }

    // MARK: CTA Section

    private var ctaSection: some View {
        VStack(spacing: 16) {
            // Primary CTA — triggers real StoreKit purchase
            Button {
                Task {
                    let purchased = await subVM.startFreeTrial()
                    if purchased {
                        onComplete()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if subVM.isLoading {
                        ProgressView()
                            .tint(Color.appButtonLabel(colorScheme))
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                        Text("Start Free Trial")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(Color.appButtonLabel(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent(colorScheme), Color.appAccent(colorScheme).opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.appAccent(colorScheme).opacity(0.45), radius: 16, y: 6)
                )
            }
            .buttonStyle(.plain)
            .disabled(subVM.isLoading)
            .scaleEffect(ctaVisible ? 1.0 : 0.9)
            .opacity(ctaVisible ? 1.0 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: ctaVisible)

            // Purchase error message
            if let errorMessage = subVM.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Secondary skip link — free tier, bypasses subscription
            Button(action: onComplete) {
                Text("Continue for Free")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appMutedText(colorScheme))
                    .underline(color: Color.appMutedText(colorScheme).opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(subVM.isLoading)
            .opacity(ctaVisible ? 1.0 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: ctaVisible)

            // Restore purchases link
            Button {
                Task {
                    await subVM.restorePurchases()
                    if subVM.isSubscribed {
                        onComplete()
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMutedText(colorScheme).opacity(0.6))
            }
            .buttonStyle(.plain)
            .disabled(subVM.isLoading)
            .opacity(ctaVisible ? 1.0 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: ctaVisible)

            // Legal disclaimer
            Text("No payment now. Cancel before trial ends to avoid being charged.")
                .font(.system(size: 11))
                .foregroundStyle(Color.appMutedText(colorScheme).opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .animation(.easeInOut(duration: 0.2), value: subVM.errorMessage)
    }
}

// MARK: - Paywall Feature

private struct PaywallFeature {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

private struct FeatureRow: View {
    let feature: PaywallFeature
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: feature.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(feature.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                Text(feature.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.appAccent(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.appBorderDynamic(colorScheme).opacity(0.25), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OnboardingPaywallView(onComplete: {})
        .environment(SubscriptionViewModel())
        .preferredColorScheme(.dark)
}
