import CoreData
import Foundation

final class StatsService {

    static let shared = StatsService()

    private let stack = CoreDataStack.shared

    private init() {}

    /// 이번 주 총 청취 시간(ms) 합산
    func totalListenedDurationMs(since date: Date) -> Int {
        let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
        request.predicate = NSPredicate(format: "startedAt >= %@", date as NSDate)
        guard let records = try? stack.context.fetch(request) else { return 0 }
        return records.reduce(0) { $0 + Int($1.listenedDurationMs) }
    }

    /// 전체 재생 기록 기준 현재 연속 청취일
    func currentListeningStreakDays() -> Int {
        let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
        request.predicate = NSPredicate(format: "listenedDurationMs > 0")
        request.propertiesToFetch = ["startedAt"]

        guard let records = try? stack.context.fetch(request) else { return 0 }

        let calendar = Calendar.current
        let listenedDays = Set(records.compactMap { record -> Date? in
            guard let startedAt = record.startedAt else { return nil }
            return calendar.startOfDay(for: startedAt)
        })

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let streakStart: Date

        if listenedDays.contains(today) {
            streakStart = today
        } else if listenedDays.contains(yesterday) {
            streakStart = yesterday
        } else {
            return 0
        }

        var streakDays = 0
        var cursor = streakStart

        while listenedDays.contains(cursor) {
            streakDays += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streakDays
    }

    /// 이번 주 재생 기록에서 장르별 재생 횟수를 집계해 상위 N개 반환
    func topGenres(since date: Date, limit: Int) -> [(name: String, count: Int)] {
        let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
        request.predicate = NSPredicate(format: "startedAt >= %@ AND isSkipped == NO", date as NSDate)

        guard let records = try? stack.context.fetch(request) else { return [] }

        var genreCount: [String: Int] = [:]
        for record in records {
            guard let genres = record.music?.genres else { continue }
            for genre in genres {
                let trimmedGenre = genre.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !["Music", "음악"].contains(trimmedGenre) else { continue }
                genreCount[trimmedGenre, default: 0] += 1
            }
        }

        return genreCount
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (name: $0.key, count: $0.value) }
    }
}
