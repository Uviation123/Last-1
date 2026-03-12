import SwiftUI
import Observation
import UserNotifications

// MARK: - SettingsViewModel
// @Observable so SwiftUI tracks property access without @Published boilerplate.
// @MainActor ensures all UI-driving state mutations happen on the main thread.
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Identity
    // These map 1-to-1 with the UserDefaults keys written by OnboardingViewModel.persistToUserDefaults().
    // Editing here updates the same store that onboarding reads, keeping them in sync.
    var currentIdentity: String = ""
    var desiredIdentity: String = ""
    var commitmentLevel: Int = 2        // 1=Light, 2=Moderate, 3=All-In (CommitmentLevel.rawValue)
    var primaryGoalId: String = ""      // First selected goal id from onboarding_goals

    // MARK: - Progress
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalLogs: Int = 0

    // Momentum label derived from streak relative to a 30-day pace
    var momentumLabel: String {
        let pace = Double(currentStreak) / 30.0
        if pace >= 0.66 { return "Strong" }
        if pace >= 0.33 { return "Stable" }
        return "Rising"
    }

    // Icon to pair with the momentum label in the header
    var momentumIcon: String {
        switch momentumLabel {
        case "Strong": return "bolt.fill"
        case "Stable": return "equal.circle.fill"
        default:       return "arrow.up.right.circle.fill"
        }
    }

    // MARK: - Notifications
    // Stored in UserDefaults via AppStorage-compatible keys so the view can bind directly.
    var dailyReminderEnabled: Bool = false
    var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    var motivationalNudgesEnabled: Bool = false
    var streakAlertEnabled: Bool = false
    var streakBrokenAlertEnabled: Bool = false

    // Set to true when the user tried to enable notifications but permission was denied
    var notificationPermissionDenied: Bool = false

    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var showResetConfirmation: Bool = false

    // MARK: - Private Repos
    private let streakRepo = StreakRepository()
    private let logRepo = DailyLogRepository()

    // UserDefaults keys for notification prefs
    private enum NotifKey {
        static let dailyReminder       = "settings_dailyReminderEnabled"
        static let reminderTime        = "settings_reminderTime"
        static let nudges              = "settings_motivationalNudgesEnabled"
        static let streakAlert         = "settings_streakAlertEnabled"
        static let streakBrokenAlert   = "settings_streakBrokenAlertEnabled"
    }

    // MARK: - Init
    init() {
        loadIdentityFromDefaults()
        loadNotificationPrefsFromDefaults()
    }

    // MARK: - Load Data

    /// Fetches streak and total-log count concurrently from Supabase.
    func loadData(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Concurrent fetches to minimise round-trip time
            async let streakFetch = streakRepo.fetchStreak(userId: userId)
            async let logsFetch   = logRepo.fetchRecentLogs(userId: userId, limit: 9999)

            let streak = try await streakFetch
            let logs   = try await logsFetch

            currentStreak  = streak?.currentStreak  ?? 0
            longestStreak  = streak?.longestStreak  ?? 0
            totalLogs      = logs.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Identity Persistence

    /// Reads onboarding identity values that were written by OnboardingViewModel.persistToUserDefaults().
    private func loadIdentityFromDefaults() {
        let d = UserDefaults.standard
        currentIdentity  = d.string(forKey: "onboarding_currentIdentity") ?? ""
        desiredIdentity  = d.string(forKey: "onboarding_desiredIdentity")  ?? ""
        commitmentLevel  = d.integer(forKey: "onboarding_commitmentLevel") == 0
                           ? 2
                           : d.integer(forKey: "onboarding_commitmentLevel")
        let goals        = d.array(forKey: "onboarding_goals") as? [String] ?? []
        primaryGoalId    = goals.first ?? ""
    }

    /// Persists edited identity values back to the same UserDefaults keys onboarding uses.
    func saveIdentity() {
        let d = UserDefaults.standard
        d.set(currentIdentity, forKey: "onboarding_currentIdentity")
        d.set(desiredIdentity,  forKey: "onboarding_desiredIdentity")
        d.set(commitmentLevel,  forKey: "onboarding_commitmentLevel")

        // Preserve other goals, just update the primary (first) goal id
        var goals = d.array(forKey: "onboarding_goals") as? [String] ?? []
        if !primaryGoalId.isEmpty {
            if let idx = goals.firstIndex(of: primaryGoalId) {
                // Move chosen goal to front without duplicating
                goals.remove(at: idx)
                goals.insert(primaryGoalId, at: 0)
            } else {
                goals.insert(primaryGoalId, at: 0)
            }
        }
        d.set(goals, forKey: "onboarding_goals")
    }

    // MARK: - Journey Reset

    /// Clears all onboarding data from UserDefaults and triggers re-onboarding on next launch.
    /// Called only after the user confirms the destructive alert.
    func resetJourney() {
        let d = UserDefaults.standard
        let keysToRemove = [
            "onboarding_goals",
            "onboarding_painPoints",
            "onboarding_currentIdentity",
            "onboarding_desiredIdentity",
            "onboarding_commitmentLevel",
            "pendingFirstLog"
        ]
        keysToRemove.forEach { d.removeObject(forKey: $0) }
        // Setting hasCompletedOnboarding to false causes Last1App to show OnboardingView
        d.set(false, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Notification Preferences

    private func loadNotificationPrefsFromDefaults() {
        let d = UserDefaults.standard
        dailyReminderEnabled      = d.bool(forKey: NotifKey.dailyReminder)
        motivationalNudgesEnabled = d.bool(forKey: NotifKey.nudges)
        streakAlertEnabled        = d.bool(forKey: NotifKey.streakAlert)
        streakBrokenAlertEnabled  = d.bool(forKey: NotifKey.streakBrokenAlert)
        if let saved = d.object(forKey: NotifKey.reminderTime) as? Date {
            reminderTime = saved
        }
    }

    private func saveNotificationPrefs() {
        let d = UserDefaults.standard
        d.set(dailyReminderEnabled,      forKey: NotifKey.dailyReminder)
        d.set(motivationalNudgesEnabled, forKey: NotifKey.nudges)
        d.set(streakAlertEnabled,        forKey: NotifKey.streakAlert)
        d.set(streakBrokenAlertEnabled,  forKey: NotifKey.streakBrokenAlert)
        d.set(reminderTime,              forKey: NotifKey.reminderTime)
    }

    // MARK: - Notification Scheduling

    /// Requests UNUserNotificationCenter permission if not already granted.
    /// Returns true if permission is authorised, false otherwise.
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        default:
            // .denied — user must change in iOS Settings
            return false
        }
    }

    /// Schedules or cancels the smart daily reminder via NotificationService.
    /// NotificationService pre-schedules the next 14 days individually and skips
    /// any day the user has already logged, preventing unnecessary reminders.
    func updateDailyReminder() {
        saveNotificationPrefs()
        NotificationService.shared.refreshDailyReminders(
            enabled: dailyReminderEnabled,
            at: reminderTime
        )
    }

    /// Schedules or cancels a streak-at-risk notification (fires at 9 PM if no log today).
    func updateStreakAlert() {
        saveNotificationPrefs()
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak_alert"])

        guard streakAlertEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your streak is at risk"
        content.body  = "Log your 1% before midnight to keep your streak alive."
        content.sound = .default

        var comps = DateComponents()
        comps.hour   = 21
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let request = UNNotificationRequest(
            identifier: "streak_alert",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Schedules or cancels the next-morning streak-broken alert via NotificationService.
    /// The alert fires at 9 AM the day after the user last logged, only if they haven't
    /// logged that day. It is rescheduled automatically each time the user saves a log.
    func updateStreakBrokenAlert() {
        saveNotificationPrefs()
        if streakBrokenAlertEnabled {
            NotificationService.shared.scheduleStreakBrokenAlert()
        } else {
            NotificationService.shared.cancelStreakBrokenAlert()
        }
    }

    /// Schedules or cancels motivational nudge notifications (fires at noon, 3 days per week).
    func updateMotivationalNudges() {
        saveNotificationPrefs()
        let center = UNUserNotificationCenter.current()
        let ids = ["nudge_mon", "nudge_wed", "nudge_fri"]
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard motivationalNudgesEnabled else { return }

        let messages = [
            "Every 1% adds up. What's yours today?",
            "Champions are built in the moments no one else sees.",
            "Small consistent actions create extraordinary results."
        ]

        // Schedule on Monday (2), Wednesday (4), Friday (6)
        let weekdays: [Int] = [2, 4, 6]
        for (i, weekday) in weekdays.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Last 1%"
            content.body  = messages[i]
            content.sound = .default

            var comps = DateComponents()
            comps.weekday = weekday
            comps.hour    = 12
            comps.minute  = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
       

            let request = UNNotificationRequest(
                identifier: ids[i],
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    // MARK: - Toggles (called from the view when a toggle changes)

    func toggleDailyReminder() async {
        if dailyReminderEnabled {
            // Just turned ON — check permission first
            let granted = await requestNotificationPermission()
            if !granted {
                dailyReminderEnabled = false
                notificationPermissionDenied = true
                return
            }
        }
        updateDailyReminder()
    }

    func toggleStreakAlert() async {
        if streakAlertEnabled {
            let granted = await requestNotificationPermission()
            if !granted {
                streakAlertEnabled = false
                notificationPermissionDenied = true
                return
            }
        }
        updateStreakAlert()
    }

    func toggleMotivationalNudges() async {
        if motivationalNudgesEnabled {
            let granted = await requestNotificationPermission()
            if !granted {
                motivationalNudgesEnabled = false
                notificationPermissionDenied = true
                return
            }
        }
        updateMotivationalNudges()
    }

    func toggleStreakBrokenAlert() async {
        if streakBrokenAlertEnabled {
            let granted = await requestNotificationPermission()
            if !granted {
                streakBrokenAlertEnabled = false
                notificationPermissionDenied = true
                return
            }
        }
        updateStreakBrokenAlert()
    }
}
