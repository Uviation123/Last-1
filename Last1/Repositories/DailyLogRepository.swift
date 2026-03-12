import Foundation
import Supabase

struct DailyLogUpdate: Encodable {
    let category: LogCategory
    let effortLevel: Int
    var note: String?

    enum CodingKeys: String, CodingKey {
        case category
        case effortLevel = "effort_level"
        case note
    }
}

struct DailyLogRepository {
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchTodayLog(userId: UUID) async throws -> DailyLog? {
        let today = DateFormatting.todayString()
        let logs: [DailyLog] = try await client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: today)
            .limit(1)
            .execute()
            .value
        return logs.first
    }

    func fetchLogs(userId: UUID, from startDate: String, to endDate: String) async throws -> [DailyLog] {
        try await client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .order("date", ascending: true)
            .execute()
            .value
    }

    func insertLog(_ log: DailyLogInsert) async throws -> DailyLog {
        try await client
            .from("daily_logs")
            .insert(log)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchRecentLogs(userId: UUID, limit: Int = 30) async throws -> [DailyLog] {
        try await client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func updateLog(id: UUID, update: DailyLogUpdate) async throws -> DailyLog {
        try await client
            .from("daily_logs")
            .update(update)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteLog(id: UUID) async throws {
        try await client
            .from("daily_logs")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
