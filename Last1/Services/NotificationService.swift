import Foundation
import UserNotifications

// MARK: - NotificationService
// Manages smart daily reminder scheduling. Instead of a single repeating notification
// (which would fire even on days the user already logged), this service schedules
// individual non-repeating notifications for the next 14 days and skips any day
// the user has already logged. Call refreshDailyReminders() on app active and
// didLogToday() whenever the user saves a log.
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // UserDefaults key that tracks the last date the user saved a log
    private let lastLogKey = "notif_lastLogDate"

    // Prefix for per-day notification identifiers ("daily_reminder_day_0" … "_13")
    private let reminderPrefix = "daily_reminder_day_"

    // How many days ahead to pre-schedule reminders
    private let lookAheadDays = 14

    // All 14 identifiers used by this service
    private var allReminderIDs: [String] {
        (0..<lookAheadDays).map { "\(reminderPrefix)\($0)" }
    }

    // Identifier for the single next-morning streak broken alert
    private let streakBrokenID = "streak_broken_alert"

    // MARK: - Public API

    /// Call this immediately after the user successfully saves a daily log.
    /// Persists today's date so subsequent refreshes know to skip it,
    /// and schedules tomorrow's streak-broken alert in case they miss the next day.
    func didLogToday() {
        UserDefaults.standard.set(DateFormatting.todayString(), forKey: lastLogKey)
        refreshDailyReminders()
        scheduleStreakBrokenAlert()
    }

    /// Schedules a single non-repeating notification for 9 AM tomorrow.
    /// If the user logs tomorrow, `didLogToday()` cancels it and reschedules
    /// for the day after. If they miss the day, it fires as a "start fresh" nudge.
    func scheduleStreakBrokenAlert() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakBrokenID])

        guard UserDefaults.standard.bool(forKey: "settings_streakBrokenAlertEnabled") else { return }

        let cal = Calendar.current
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) else { return }

        var fireComps        = cal.dateComponents([.year, .month, .day], from: tomorrow)
        fireComps.hour       = 9
        fireComps.minute     = 0
        fireComps.second     = 0

        let totalLogs = UserDefaults.standard.integer(forKey: "notif_totalLogs")
        let dayWord   = totalLogs == 1 ? "day" : "days"

        let content          = UNMutableNotificationContent()
        content.title        = "Even the best slip up."
        content.subtitle     = "You've logged \(totalLogs) \(dayWord) — that growth isn't going anywhere."
        content.body         = "Start your next streak today."
        content.sound        = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComps, repeats: false)
        let request = UNNotificationRequest(
            identifier: streakBrokenID,
            content:    content,
            trigger:    trigger
        )
        center.add(request)
    }

    /// Cancels a pending streak-broken alert (e.g. when the feature is toggled off).
    func cancelStreakBrokenAlert() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [streakBrokenID])
    }

    /// Re-evaluates and reschedules the next 14 daily reminders.
    /// Reads the current enabled/time preferences from UserDefaults so it can be
    /// called without needing to pass any arguments (e.g. from scenePhase changes).
    func refreshDailyReminders() {
        let d = UserDefaults.standard
        let enabled = d.bool(forKey: "settings_dailyReminderEnabled")
        let time = (d.object(forKey: "settings_reminderTime") as? Date) ?? defaultTime()
        refreshDailyReminders(enabled: enabled, at: time)
    }

    /// Schedules (or cancels) per-day notifications for the next `lookAheadDays` days.
    /// Called directly by SettingsViewModel when the user changes enabled/time settings.
    func refreshDailyReminders(enabled: Bool, at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allReminderIDs)

        guard enabled else { return }

        let today    = DateFormatting.todayString()
        let lastLog  = UserDefaults.standard.string(forKey: lastLogKey)
        let cal      = Calendar.current
        let comps    = cal.dateComponents([.hour, .minute], from: time)
        let hour     = comps.hour   ?? 20
        let minute   = comps.minute ?? 0
        let now      = Date()

        for offset in 0..<lookAheadDays {
            guard let targetDate = cal.date(byAdding: .day, value: offset, to: now) else { continue }

            // Skip today if user already logged
            if offset == 0 && lastLog == today { continue }

            // Skip today if the chosen reminder time has already passed
            if offset == 0 {
                guard let todayAtTime = cal.date(
                    bySettingHour: hour, minute: minute, second: 0, of: now
                ), todayAtTime > now else { continue }
            }

            var fireComps        = cal.dateComponents([.year, .month, .day], from: targetDate)
            fireComps.hour       = hour
            fireComps.minute     = minute
            fireComps.second     = 0

            let content       = UNMutableNotificationContent()
            content.title     = "Time for your 1%"
            content.body      = "A small action today compounds into something great. Log it now."
            content.sound     = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: fireComps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(reminderPrefix)\(offset)",
                content:    content,
                trigger:    trigger
            )
            center.add(request)
        }
    }

    // MARK: - Helpers

    private func defaultTime() -> Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
