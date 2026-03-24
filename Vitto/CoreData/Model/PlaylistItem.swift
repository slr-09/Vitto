import CoreData

class PlaylistItem: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var orderIndex: Int32
    @NSManaged var addedAt: Date?
    @NSManaged var playlist: PlaylistEntity?
    @NSManaged var music: MusicEntity?
}
