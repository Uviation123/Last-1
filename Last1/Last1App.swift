import SwiftUI
import Supabase
import GoogleSignIn

@main
struct Last1App: App {
    @State private var authViewModel = AuthViewModel()
    @State private var subscriptionViewModel = SubscriptionViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.dark.rawValue

    private var preferredColorScheme: ColorScheme? {
        (AppearanceMode(rawValue: appearanceModeRaw) ?? .dark).colorScheme
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(authViewModel)
                        .environment(subscriptionViewModel)
                } else {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .environment(authViewModel)
                    .environment(subscriptionViewModel)
                }
            }
            .preferredColorScheme(preferredColorScheme)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
                Task {
                    do {
                        try await SupabaseManager.client.auth.session(from: url)
                    } catch {}
                }
            }
        }
    }
}
