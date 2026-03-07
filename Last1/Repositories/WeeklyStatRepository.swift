import Foundation
import Supabase

struct WeeklyStatRepository {
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchCurrentWeek(userId: UUID) async throws -> WeeklyStat? {
        let weekStart = DateFormatting.startOfWeek()
        let stats: [WeeklyStat] = try await client
            .from("weekly_stats")
            .select()
            .eq("user_id", value: userId)
            .eq("week_start_date", value: weekStart)
            .limit(1)
            .execute()
            .value
        return stats.first
    }

    func fetchWeeklyStats(userId: UUID, limit: Int = 12) async throws -> [WeeklyStat] {
        try await client
            .from("weekly_stats")
            .select()
            .eq("user_id", value: userId)
            .order("week_start_date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func upsertWeeklyStat(
        userId: UUID,
        weekStart: String,
        logsCount: Int,
        strongest: String?,
        weakest: String?
    ) async throws {
        struct WeeklyStatUpsert: Encodable {
            let userId: UUID
            let weekStartDate: String
            let logsCount: Int
            let strongestCategory: String?
            let weakestCategory: String?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case weekStartDate = "week_start_date"
                case logsCount = "logs_count"
                case strongestCategory = "strongest_category"
                case weakestCategory = "weakest_category"
            }
        }

        try await client
            .from("weekly_stats")
            .upsert(
                WeeklyStatUpsert(
                    userId: userId,
                    weekStartDate: weekStart,
                    logsCount: logsCount,
                    strongestCategory: strongest,
                    weakestCategory: weakest
                ),
                onConflict: "user_id,week_start_date"
            )
            .execute()
    }
}
