import Foundation
import Supabase
import Storage

struct StorageService {
    private var client: SupabaseClient { SupabaseManager.client }

    func uploadPhoto(imageData: Data, userId: UUID) async throws -> String {
        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"

        try await client.storage
            .from("log-photos")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: false
                )
            )

        let publicURL = try client.storage
            .from("log-photos")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }
}
