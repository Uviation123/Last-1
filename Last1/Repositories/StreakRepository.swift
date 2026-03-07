import Foundation
import Supabase

struct StreakRepository {
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchStreak(userId: UUID) async throws -> Streak? {
        let streaks: [Streak] = try await client
            .from("streaks")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return streaks.first
    }

    func upsertStreak(_ streak: StreakUpsert) async throws {
        try await client
            .from("streaks")
            .upsert(streak, onConflict: "user_id")
            .execute()
    }
}
