import CoreData
import RxSwift

final class PlaylistService {

    static let shared = PlaylistService()

    private let stack = CoreDataStack.shared
    private init() {}

    // MARK: - Create

    /// 새 플레이리스트 생성
    @discardableResult
    func createPlaylist(name: String, description: String? = nil, coverImageUrl: String? = nil) -> PlaylistEntity {
        let ctx = stack.context
        let playlist = PlaylistEntity(
            entity: NSEntityDescription.entity(forEntityName: "PlaylistEntity", in: ctx)!,
            insertInto: ctx
        )
        playlist.id = UUID()
        playlist.name = name
        playlist.playlistDescription = description
        playlist.coverImageUrl = coverImageUrl
        playlist.createdAt = Date()
        playlist.updatedAt = Date()

        stack.saveContext()
        return playlist
    }

    // MARK: - Read

    /// 모든 플레이리스트 조회 (생성일 내림차순)
    func fetchAllPlaylists() -> Observable<[Playlist]> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let ctx = self.stack.context
            let request = NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            do {
                let entities = try ctx.fetch(request)
                let playlists = entities.map { $0.toPlaylist() }
                observer.onNext(playlists)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    /// ID로 플레이리스트 조회
    func fetchPlaylist(id: UUID) -> Observable<Playlist?> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let ctx = self.stack.context
            let request = NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let entity = try ctx.fetch(request).first
                observer.onNext(entity?.toPlaylist())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Update

    /// 플레이리스트 이름 변경
    func renamePlaylist(_ playlist: PlaylistEntity, to name: String) {
        playlist.name = name
        playlist.updatedAt = Date()
        stack.saveContext()
    }

    /// 플레이리스트 설명 변경
    func updateDescription(_ playlist: PlaylistEntity, description: String?) {
        playlist.playlistDescription = description
        playlist.updatedAt = Date()
        stack.saveContext()
    }

    // MARK: - Delete

    /// 플레이리스트 삭제 (PlaylistItem은 cascade로 자동 삭제, MusicEntity는 유지)
    func deletePlaylist(_ playlist: PlaylistEntity) {
        stack.context.delete(playlist)
        stack.saveContext()
    }

    // MARK: - Song Management

    /// 플레이리스트에 곡 추가
    func addSong(_ music: Music, to playlist: PlaylistEntity) {
        let ctx = stack.context
        let musicEntity = MusicEntity.findOrCreate(from: music, in: ctx)

        let item = PlaylistItem(
            entity: NSEntityDescription.entity(forEntityName: "PlaylistItem", in: ctx)!,
            insertInto: ctx
        )
        item.id = UUID()
        item.music = musicEntity
        item.playlist = playlist
        item.addedAt = Date()

        // 현재 가장 큰 orderIndex + 1
        let currentMax = playlist.sortedItems.last?.orderIndex ?? -1
        item.orderIndex = currentMax + 1

        playlist.updatedAt = Date()
        stack.saveContext()
    }

    /// 플레이리스트에서 곡 제거 후 orderIndex 재정렬
    func removeSong(at index: Int, from playlist: PlaylistEntity) {
        let sorted = playlist.sortedItems
        guard index >= 0 && index < sorted.count else { return }

        stack.context.delete(sorted[index])

        // orderIndex 재정렬
        let remaining = playlist.sortedItems
        for (i, item) in remaining.enumerated() {
            item.orderIndex = Int32(i)
        }

        playlist.updatedAt = Date()
        stack.saveContext()
    }

    /// 곡 순서 변경
    func reorderSong(in playlist: PlaylistEntity, from sourceIndex: Int, to destinationIndex: Int) {
        var sorted = playlist.sortedItems
        guard sourceIndex >= 0 && sourceIndex < sorted.count,
              destinationIndex >= 0 && destinationIndex < sorted.count else { return }

        let movedItem = sorted.remove(at: sourceIndex)
        sorted.insert(movedItem, at: destinationIndex)

        for (i, item) in sorted.enumerated() {
            item.orderIndex = Int32(i)
        }

        playlist.updatedAt = Date()
        stack.saveContext()
    }

}
