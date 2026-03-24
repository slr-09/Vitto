import CoreData

class PlaylistEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var playlistDescription: String?
    @NSManaged var coverImageUrl: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var items: NSSet?
}

// MARK: - Convenience

extension PlaylistEntity {

    /// PlaylistItem을 orderIndex 순으로 정렬하여 반환
    var sortedItems: [PlaylistItem] {
        guard let items = items as? Set<PlaylistItem> else { return [] }
        return items.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// 플레이리스트의 곡 목록을 Music 배열로 변환
    func toMusicArray() -> [Music] {
        sortedItems.compactMap { $0.music?.toMusic() }
    }

    /// Playlist 값 타입으로 변환
    func toPlaylist() -> Playlist {
        Playlist(
            id: id ?? UUID(),
            name: name ?? "",
            description: playlistDescription,
            coverImageUrl: coverImageUrl,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            songs: toMusicArray()
        )
    }
}
