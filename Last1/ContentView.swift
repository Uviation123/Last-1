import SwiftUI

enum AppTab: CaseIterable {
    case home, growth, weekly, profile

    var label: String {
        switch self {
        case .home: "Home"
        case .growth: "Growth"
        case .weekly: "Weekly"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .growth: "chart.line.uptrend.xyaxis"
        case .weekly: "calendar"
        case .profile: "person.fill"
        }
    }
}

struct ContentView: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme
    @State private var activeTab: AppTab = .home
    @State private var showAddLog = false

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                mainTabInterface
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authVM.isAuthenticated)
    }

    private var mainTabInterface: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground(colorScheme).ignoresSafeArea()

            // Screen content
            Group {
                switch activeTab {
                case .home:    HomeView()
                case .growth:  GrowthView()
                case .weekly:  WeeklySummaryView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddLog) {
            AddLogView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Home
            tabButton(tab: .home)

            // Growth
            tabButton(tab: .growth)

            // Center Add button
            addButton

            // Weekly
            tabButton(tab: .weekly)

            // Profile
            tabButton(tab: .profile)
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(colorScheme == .dark
                      ? Color.appSecondary.opacity(0.6)
                      : Color.appTabBar(colorScheme))
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(colorScheme == .dark
                              ? Color.glassBorder.opacity(0.3)
                              : Color.black.opacity(0.06))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func tabButton(tab: AppTab) -> some View {
        let isActive = activeTab == tab
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                activeTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .top) {
                    // Active pill indicator at top
                    Capsule()
                        .fill(isActive ? Color.appAccent(colorScheme) : .clear)
                        .frame(width: 20, height: 3)
                        .offset(y: -6)

                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(isActive ? Color.appAccent(colorScheme) : Color.appMutedText(colorScheme))

                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isActive ? Color.appAccent(colorScheme) : Color.appMutedText(colorScheme))
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button {
            showAddLog = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.appAccent(colorScheme))
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.appAccent(colorScheme).opacity(0.4), radius: 10, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appButtonLabel(colorScheme))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showAddLog)
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
