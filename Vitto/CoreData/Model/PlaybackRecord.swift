import CoreData

class PlaybackRecord: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var startedAt: Date?
    @NSManaged var listenedDurationMs: Int32
    @NSManaged var completionRate: Float
    @NSManaged var isCompleted: Bool
    @NSManaged var isSkipped: Bool
    @NSManaged var moodRawValue: String?
    @NSManaged var music: MusicEntity?
}

// MARK: - Convenience

extension PlaybackRecord {

    /// moodRawValue를 MoodType으로 변환
    var mood: MoodType? {
        guard let raw = moodRawValue else { return nil }
        return MoodType(rawValue: raw)
    }
}
