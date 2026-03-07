import Foundation

enum DateFormatting {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    static func todayString() -> String {
        dayFormatter.string(from: Date())
    }

    static func dateString(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        dayFormatter.date(from: string)
    }

    static func displayString(from dateString: String) -> String {
        guard let date = date(from: dateString) else { return dateString }
        return displayFormatter.string(from: date)
    }

    static func weekday(from dateString: String) -> String {
        guard let date = date(from: dateString) else { return "" }
        return weekdayFormatter.string(from: date)
    }

    static func startOfWeek(for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let weekStart = calendar.date(from: components) else {
            return dateString(from: date)
        }
        return dateString(from: weekStart)
    }

    static func daysAgo(_ days: Int, from date: Date = Date()) -> String {
        let target = Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
        return dateString(from: target)
    }
}
