import Foundation

struct WeeklyStat: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let weekStartDate: String
    var logsCount: Int
    var strongestCategory: String?
    var weakestCategory: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekStartDate = "week_start_date"
        case logsCount = "logs_count"
        case strongestCategory = "strongest_category"
        case weakestCategory = "weakest_category"
    }
}
