import CoreData

class MusicEntity: NSManagedObject {
    @NSManaged var musicID: String?
    @NSManaged var title: String?
    @NSManaged var artist: String?
    @NSManaged var albumTitle: String?
    @NSManaged var totalDurationMs: Int32
    @NSManaged var isrc: String?
    @NSManaged var artworkUrl: String?
    @NSManaged var cachedAt: Date?
    @NSManaged var genres: [String]?
    @NSManaged var records: NSSet?
    @NSManaged var playlistItems: NSSet?
}

// MARK: - Convenience

extension MusicEntity {

    /// 기존 MusicEntity를 찾거나 없으면 새로 생성
    static func findOrCreate(
        from music: Music,
        in context: NSManagedObjectContext
    ) -> MusicEntity {
        let request = NSFetchRequest<MusicEntity>(entityName: "MusicEntity")
        request.predicate = NSPredicate(format: "musicID == %@", music.musicID)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            // preview 길이(~30s)로 저장된 경우 실제 길이로 갱신
            if music.totalDurationMs > existing.totalDurationMs {
                existing.totalDurationMs = Int32(music.totalDurationMs)
            }
            return existing
        }

        let entity = MusicEntity(
            entity: NSEntityDescription.entity(forEntityName: "MusicEntity", in: context)!,
            insertInto: context
        )
        entity.musicID = music.musicID
        entity.title = music.title
        entity.artist = music.artist
        entity.albumTitle = music.albumTitle
        entity.genres = music.genres
        entity.totalDurationMs = Int32(music.totalDurationMs)
        entity.isrc = music.isrc
        entity.artworkUrl = music.artworkUrl
        entity.cachedAt = Date()
        return entity
    }

    /// CoreData 엔티티를 Music 값 타입으로 변환
    func toMusic() -> Music {
        Music(
            musicID: musicID ?? "",
            title: title ?? "",
            artist: artist ?? "",
            totalDurationMs: Int(totalDurationMs),
            isrc: isrc ?? "",
            albumTitle: albumTitle ?? "",
            artworkUrl: artworkUrl ?? "",
            genres: genres ?? []
        )
    }
}
