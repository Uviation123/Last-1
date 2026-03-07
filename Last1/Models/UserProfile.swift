import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let createdAt: String?
    var email: String?
    var username: String?
    var avatarUrl: String?
    var timezone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case email
        case username
        case avatarUrl = "avatar_url"
        case timezone
    }
}

struct UserProfileUpdate: Encodable {
    var username: String?
    var avatarUrl: String?
    var timezone: String?

    enum CodingKeys: String, CodingKey {
        case username
        case avatarUrl = "avatar_url"
        case timezone
    }
}
