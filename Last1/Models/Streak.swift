import Foundation

struct Streak: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastLogDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastLogDate = "last_log_date"
    }
}

struct StreakUpsert: Encodable {
    let userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastLogDate: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastLogDate = "last_log_date"
    }
}
