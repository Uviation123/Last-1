import SwiftUI
import Observation

// MARK: - Pending Log Data
// Stored in UserDefaults after Screen 7 so HomeViewModel can sync to Supabase post-auth.
struct PendingLogData: Codable {
    let date: String
    let category: LogCategory
    let effortLevel: Int
    var note: String?
}

// MARK: - Onboarding Goal
// 9 predefined goal categories shown on the goal-selection screen.
struct OnboardingGoal: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
}

extension OnboardingGoal {
    static let all: [OnboardingGoal] = [
        OnboardingGoal(id: "fitness",       label: "Get Fitter",          icon: "figure.run",              color: .orange),
        OnboardingGoal(id: "learning",      label: "Learn More",           icon: "book.fill",               color: .blue),
        OnboardingGoal(id: "mindfulness",   label: "Find Balance",         icon: "brain.head.profile",      color: .purple),
        OnboardingGoal(id: "nutrition",     label: "Eat Better",           icon: "leaf.fill",               color: .green),
        OnboardingGoal(id: "productivity",  label: "Be Productive",        icon: "checkmark.circle.fill",   color: .indigo),
        OnboardingGoal(id: "creativity",    label: "Create More",          icon: "paintbrush.fill",         color: .pink),
        OnboardingGoal(id: "social",        label: "Strengthen Bonds",     icon: "person.2.fill",           color: .yellow),
        OnboardingGoal(id: "sleep",         label: "Sleep Better",         icon: "moon.fill",               color: Color(red: 0.4, green: 0.6, blue: 1.0)),
        OnboardingGoal(id: "finance",       label: "Build Wealth",         icon: "dollarsign.circle.fill",  color: Color(red: 0.3, green: 0.85, blue: 0.5)),
    ]
}

// MARK: - Onboarding Pain Point
struct OnboardingPainPoint: Identifiable {
    let id: String
    let label: String
    let icon: String
}

extension OnboardingPainPoint {
    static let all: [OnboardingPainPoint] = [
        OnboardingPainPoint(id: "no_motivation",   label: "No motivation",              icon: "battery.0"),
        OnboardingPainPoint(id: "too_busy",        label: "Too busy",                   icon: "clock.fill"),
        OnboardingPainPoint(id: "give_up",         label: "Give up too easily",         icon: "arrow.uturn.backward"),
        OnboardingPainPoint(id: "dont_know",       label: "Don't know where to start",  icon: "questionmark.circle"),
        OnboardingPainPoint(id: "distracted",      label: "Easily distracted",          icon: "bolt.slash"),
        OnboardingPainPoint(id: "forget",          label: "Forget to log",              icon: "bell.slash"),
        OnboardingPainPoint(id: "accountability",  label: "No accountability",          icon: "person.fill.questionmark"),
        OnboardingPainPoint(id: "overwhelmed",     label: "Overwhelmed by big goals",   icon: "mountain.2"),
    ]
}

// MARK: - Commitment Level
enum CommitmentLevel: Int, CaseIterable {
    case light    = 1
    case moderate = 2
    case allIn    = 3

    var label: String {
        switch self {
        case .light:    return "Light"
        case .moderate: return "Moderate"
        case .allIn:    return "All-In"
        }
    }

    var description: String {
        switch self {
        case .light:    return "5–10 min/day. Sustainable and steady."
        case .moderate: return "15–20 min/day. Balanced growth."
        case .allIn:    return "30+ min/day. Maximum momentum."
        }
    }

    var barCount: Int { rawValue }
}

// MARK: - OnboardingViewModel
// Central @Observable state shared across all 8 onboarding screens via .environment(vm).
// Persists selections to UserDefaults so data survives app restarts during onboarding.
@Observable
class OnboardingViewModel {

    // Screen 2 – Goal selection
    var selectedGoals: Set<String> = []

    // Screen 3 – Pain point identification
    var selectedPainPoints: Set<String> = []

    // Screen 4 – Identity reflection
    var currentIdentity: String = ""
    var desiredIdentity: String = ""

    // Screen 5 – Commitment level (1=Light, 2=Moderate, 3=All-In)
    var commitmentLevel: Int = 2

    // Screen 7 – First log entry
    var firstLogCategory: LogCategory = .fitness
    var firstLogEffort: Double = 3
    var firstLogNote: String = ""
    var firstLogImage: UIImage? = nil
    var firstLogCompleted: Bool = false

    // MARK: Persistence

    /// Writes all onboarding selections to UserDefaults with the onboarding_ prefix.
    /// Called after Screen 7 completes and before the paywall is shown.
    func persistToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(Array(selectedGoals),    forKey: "onboarding_goals")
        defaults.set(Array(selectedPainPoints), forKey: "onboarding_painPoints")
        defaults.set(currentIdentity,         forKey: "onboarding_currentIdentity")
        defaults.set(desiredIdentity,         forKey: "onboarding_desiredIdentity")
        defaults.set(commitmentLevel,         forKey: "onboarding_commitmentLevel")
    }

    /// Saves the first log as a PendingLogData so HomeViewModel can sync it after authentication.
    func savePendingFirstLog() {
        let pending = PendingLogData(
            date: DateFormatting.todayString(),
            category: firstLogCategory,
            effortLevel: Int(firstLogEffort.rounded()),
            note: firstLogNote.isEmpty ? nil : firstLogNote
        )
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: "pendingFirstLog")
        }
        firstLogCompleted = true
        persistToUserDefaults()
    }

    // MARK: Helpers

    var commitmentLevelEnum: CommitmentLevel {
        CommitmentLevel(rawValue: commitmentLevel) ?? .moderate
    }

    /// Returns a human-readable summary of selected goals for the growth result screen.
    var goalsSummary: String {
        let labels = OnboardingGoal.all
            .filter { selectedGoals.contains($0.id) }
            .map { $0.label }
        guard !labels.isEmpty else { return "your goals" }
        if labels.count == 1 { return labels[0] }
        if labels.count == 2 { return "\(labels[0]) and \(labels[1])" }
        return "\(labels[0]), \(labels[1]), and \(labels.count - 2) more"
    }

    /// Returns an icon for the first selected goal (used on growth result screen).
    var primaryGoalIcon: String {
        OnboardingGoal.all.first(where: { selectedGoals.contains($0.id) })?.icon ?? "star.fill"
    }
}
