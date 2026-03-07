import Foundation
import Supabase

struct UserRepository {
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    func updateProfile(userId: UUID, update: UserProfileUpdate) async throws {
        try await client
            .from("users")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }
}
