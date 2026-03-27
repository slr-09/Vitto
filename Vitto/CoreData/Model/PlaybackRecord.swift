import CoreData

class PlaybackRecord: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var startedAt: Date?
    @NSManaged var listenedDurationMs: Int32
    @NSManaged var completionRate: Float
    @NSManaged var isCompleted: Bool
    @NSManaged var isSkipped: Bool
    @NSManaged var moodRawValue: String?
    @NSManaged var weatherCondition: String?
    @NSManaged var weatherTemperature: Double
    @NSManaged var music: MusicEntity?
}
