import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    private init() {}

    // MARK: - Persistent Container

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "Vitto",
            managedObjectModel: Self.managedObjectModel
        )
        // 새 엔티티 추가 시 lightweight migration 지원
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("[CoreDataStack] 저장소 로드 실패: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        let ctx = context
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                print("[CoreDataStack] 저장 실패: \(error)")
            }
        }
    }

    /// 카탈로그에서 가져온 실제 duration으로 CoreData의 MusicEntity를 갱신
    func updateMusicDurations(_ musics: [Music]) {
        let ctx = context
        for music in musics {
            let _ = MusicEntity.findOrCreate(from: music, in: ctx)
        }
        saveContext()
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    // MARK: - Programmatic CoreData Model

    private static var managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        // MARK: MusicEntity
        let musicEntity = NSEntityDescription()
        musicEntity.name = "MusicEntity"
        musicEntity.managedObjectClassName = NSStringFromClass(MusicEntity.self)

        let musicID = NSAttributeDescription()
        musicID.name = "musicID"
        musicID.attributeType = .stringAttributeType

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType

        let artist = NSAttributeDescription()
        artist.name = "artist"
        artist.attributeType = .stringAttributeType

        let albumTitle = NSAttributeDescription()
        albumTitle.name = "albumTitle"
        albumTitle.attributeType = .stringAttributeType

        let totalDurationMs = NSAttributeDescription()
        totalDurationMs.name = "totalDurationMs"
        totalDurationMs.attributeType = .integer32AttributeType

        let isrc = NSAttributeDescription()
        isrc.name = "isrc"
        isrc.attributeType = .stringAttributeType

        let artworkUrl = NSAttributeDescription()
        artworkUrl.name = "artworkUrl"
        artworkUrl.attributeType = .stringAttributeType

        let cachedAt = NSAttributeDescription()
        cachedAt.name = "cachedAt"
        cachedAt.attributeType = .dateAttributeType

        let favoritedAt = NSAttributeDescription()
        favoritedAt.name = "favoritedAt"
        favoritedAt.attributeType = .dateAttributeType
        favoritedAt.isOptional = true

        // MARK: PlaybackRecord
        let recordEntity = NSEntityDescription()
        recordEntity.name = "PlaybackRecord"
        recordEntity.managedObjectClassName = NSStringFromClass(PlaybackRecord.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType

        let startedAt = NSAttributeDescription()
        startedAt.name = "startedAt"
        startedAt.attributeType = .dateAttributeType

        let listenedDurationMs = NSAttributeDescription()
        listenedDurationMs.name = "listenedDurationMs"
        listenedDurationMs.attributeType = .integer32AttributeType

        let completionRate = NSAttributeDescription()
        completionRate.name = "completionRate"
        completionRate.attributeType = .floatAttributeType

        let isCompleted = NSAttributeDescription()
        isCompleted.name = "isCompleted"
        isCompleted.attributeType = .booleanAttributeType

        let isSkipped = NSAttributeDescription()
        isSkipped.name = "isSkipped"
        isSkipped.attributeType = .booleanAttributeType

        let moodRawValue = NSAttributeDescription()
        moodRawValue.name = "moodRawValue"
        moodRawValue.attributeType = .stringAttributeType

        let weatherCondition = NSAttributeDescription()
        weatherCondition.name = "weatherCondition"
        weatherCondition.attributeType = .stringAttributeType
        weatherCondition.isOptional = true

        let weatherTemperature = NSAttributeDescription()
        weatherTemperature.name = "weatherTemperature"
        weatherTemperature.attributeType = .doubleAttributeType
        weatherTemperature.defaultValue = 0

        // MARK: PlaylistEntity
        let playlistEntity = NSEntityDescription()
        playlistEntity.name = "PlaylistEntity"
        playlistEntity.managedObjectClassName = NSStringFromClass(PlaylistEntity.self)

        let playlistID = NSAttributeDescription()
        playlistID.name = "id"
        playlistID.attributeType = .UUIDAttributeType

        let playlistName = NSAttributeDescription()
        playlistName.name = "name"
        playlistName.attributeType = .stringAttributeType

        let playlistDescription = NSAttributeDescription()
        playlistDescription.name = "playlistDescription"
        playlistDescription.attributeType = .stringAttributeType
        playlistDescription.isOptional = true

        let coverImageUrl = NSAttributeDescription()
        coverImageUrl.name = "coverImageUrl"
        coverImageUrl.attributeType = .stringAttributeType
        coverImageUrl.isOptional = true

        let playlistCreatedAt = NSAttributeDescription()
        playlistCreatedAt.name = "createdAt"
        playlistCreatedAt.attributeType = .dateAttributeType

        let playlistUpdatedAt = NSAttributeDescription()
        playlistUpdatedAt.name = "updatedAt"
        playlistUpdatedAt.attributeType = .dateAttributeType

        // MARK: PlaylistItem
        let playlistItemEntity = NSEntityDescription()
        playlistItemEntity.name = "PlaylistItem"
        playlistItemEntity.managedObjectClassName = NSStringFromClass(PlaylistItem.self)

        let itemID = NSAttributeDescription()
        itemID.name = "id"
        itemID.attributeType = .UUIDAttributeType

        let orderIndex = NSAttributeDescription()
        orderIndex.name = "orderIndex"
        orderIndex.attributeType = .integer32AttributeType

        let addedAt = NSAttributeDescription()
        addedAt.name = "addedAt"
        addedAt.attributeType = .dateAttributeType

        // MARK: Relationships
        // music -> records
        let musicToRecords = NSRelationshipDescription()
        musicToRecords.name = "records"
        musicToRecords.destinationEntity = recordEntity
        musicToRecords.maxCount = 0 // one-to-many
        musicToRecords.deleteRule = .cascadeDeleteRule  // 음악 삭제 -> 기록 삭제
        musicToRecords.isOptional = true

        // records -> music
        let recordToMusic = NSRelationshipDescription()
        recordToMusic.name = "music"
        recordToMusic.destinationEntity = musicEntity
        recordToMusic.maxCount = 1  // to-one
        recordToMusic.deleteRule = .nullifyDeleteRule   // 기록 삭제 -> 음악 유지

        // Inverse 설정
        musicToRecords.inverseRelationship = recordToMusic
        recordToMusic.inverseRelationship = musicToRecords

        // playlist -> items (one-to-many)
        let playlistToItems = NSRelationshipDescription()
        playlistToItems.name = "items"
        playlistToItems.destinationEntity = playlistItemEntity
        playlistToItems.maxCount = 0
        playlistToItems.deleteRule = .cascadeDeleteRule
        playlistToItems.isOptional = true

        // item -> playlist (to-one)
        let itemToPlaylist = NSRelationshipDescription()
        itemToPlaylist.name = "playlist"
        itemToPlaylist.destinationEntity = playlistEntity
        itemToPlaylist.maxCount = 1
        itemToPlaylist.deleteRule = .nullifyDeleteRule

        // item -> music (to-one)
        let itemToMusic = NSRelationshipDescription()
        itemToMusic.name = "music"
        itemToMusic.destinationEntity = musicEntity
        itemToMusic.maxCount = 1
        itemToMusic.deleteRule = .nullifyDeleteRule

        // music -> playlistItems (one-to-many)
        let musicToPlaylistItems = NSRelationshipDescription()
        musicToPlaylistItems.name = "playlistItems"
        musicToPlaylistItems.destinationEntity = playlistItemEntity
        musicToPlaylistItems.maxCount = 0
        musicToPlaylistItems.deleteRule = .cascadeDeleteRule
        musicToPlaylistItems.isOptional = true

        // Inverse 설정
        playlistToItems.inverseRelationship = itemToPlaylist
        itemToPlaylist.inverseRelationship = playlistToItems
        itemToMusic.inverseRelationship = musicToPlaylistItems
        musicToPlaylistItems.inverseRelationship = itemToMusic

        // MARK: GenreEntity (독립 엔티티 — 장르 카탈로그 캐싱용)
        let genreEntity = NSEntityDescription()
        genreEntity.name = "GenreEntity"
        genreEntity.managedObjectClassName = NSStringFromClass(GenreEntity.self)

        let genreID = NSAttributeDescription()
        genreID.name = "genreID"
        genreID.attributeType = .stringAttributeType
        genreID.isOptional = true

        let genreName = NSAttributeDescription()
        genreName.name = "name"
        genreName.attributeType = .stringAttributeType

        let genreCachedAt = NSAttributeDescription()
        genreCachedAt.name = "cachedAt"
        genreCachedAt.attributeType = .dateAttributeType
        genreCachedAt.isOptional = true

        // MusicEntity에 genreNames Transformable 속성 추가
        let genres = NSAttributeDescription()
        genres.name = "genres"
        genres.attributeType = .transformableAttributeType
        genres.valueTransformerName = "NSSecureUnarchiveFromData"
        genres.isOptional = true

        // Entity에 속성 할당
        musicEntity.properties = [
            musicID, title, artist, albumTitle,
            totalDurationMs, isrc, artworkUrl, cachedAt, favoritedAt,
            genres,
            musicToRecords, musicToPlaylistItems
        ]
        musicEntity.uniquenessConstraints = [[musicID]]

        recordEntity.properties = [
            id, startedAt, listenedDurationMs,
            completionRate, isCompleted, isSkipped,
            moodRawValue, weatherCondition, weatherTemperature,
            recordToMusic
        ]

        playlistEntity.properties = [
            playlistID, playlistName, playlistDescription,
            coverImageUrl, playlistCreatedAt, playlistUpdatedAt,
            playlistToItems
        ]

        playlistItemEntity.properties = [
            itemID, orderIndex, addedAt,
            itemToPlaylist, itemToMusic
        ]

        genreEntity.properties = [
            genreID, genreName, genreCachedAt
        ]
        genreEntity.uniquenessConstraints = [[genreName]]

        model.entities = [musicEntity, recordEntity, playlistEntity, playlistItemEntity, genreEntity]
        return model
    }()
}
