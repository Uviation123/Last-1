import Foundation

struct DailyLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: String
    var category: LogCategory
    var effortLevel: Int
    var note: String?
    var photoUrl: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case category
        case effortLevel = "effort_level"
        case note
        case photoUrl = "photo_url"
        case createdAt = "created_at"
    }
}

struct DailyLogInsert: Encodable {
    let userId: UUID
    let date: String
    let category: LogCategory
    let effortLevel: Int
    var note: String?
    var photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case category
        case effortLevel = "effort_level"
        case note
        case photoUrl = "photo_url"
    }
}
