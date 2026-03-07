import SwiftUI
import PhotosUI
import Observation

@Observable
class AddLogViewModel {
    var selectedCategory: LogCategory = .fitness
    var effortLevel: Double = 3
    var note: String = ""
    var selectedPhotoItem: PhotosPickerItem?
    var selectedImageData: Data?
    var isLoading = false
    var errorMessage: String?
    var isSaved = false
    var alreadyLoggedToday = false

    private let logRepo = DailyLogRepository()
    private let streakRepo = StreakRepository()
    private let storageService = StorageService()

    var effortInt: Int {
        Int(effortLevel.rounded())
    }

    func loadPhoto() async {
        guard let item = selectedPhotoItem else { return }
        selectedImageData = try? await item.loadTransferable(type: Data.self)
    }

    func saveLog(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            if let _ = try await logRepo.fetchTodayLog(userId: userId) {
                alreadyLoggedToday = true
                isLoading = false
                return
            }

            var photoUrl: String?
            if let imageData = selectedImageData {
                photoUrl = try await storageService.uploadPhoto(
                    imageData: imageData,
                    userId: userId
                )
            }

            let insert = DailyLogInsert(
                userId: userId,
                date: DateFormatting.todayString(),
                category: selectedCategory,
                effortLevel: effortInt,
                note: note.isEmpty ? nil : note,
                photoUrl: photoUrl
            )

            _ = try await logRepo.insertLog(insert)
            try await updateStreak(userId: userId)
            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func updateStreak(userId: UUID) async throws {
        let existing = try await streakRepo.fetchStreak(userId: userId)
        let today = DateFormatting.todayString()
        let yesterday = DateFormatting.daysAgo(1)

        var current = 1
        var longest = existing?.longestStreak ?? 0

        if let lastDate = existing?.lastLogDate {
            if lastDate == yesterday {
                current = (existing?.currentStreak ?? 0) + 1
            } else if lastDate == today {
                current = existing?.currentStreak ?? 1
            }
        }

        longest = max(longest, current)

        try await streakRepo.upsertStreak(
            StreakUpsert(
                userId: userId,
                currentStreak: current,
                longestStreak: longest,
                lastLogDate: today
            )
        )
    }
}
