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

        let genre = NSAttributeDescription()
        genre.name = "genre"
        genre.attributeType = .stringAttributeType

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

        // Entity에 속성 할당
        musicEntity.properties = [
            musicID, title, artist, albumTitle, genre,
            totalDurationMs, isrc, artworkUrl, cachedAt,
            musicToRecords
        ]
        musicEntity.uniquenessConstraints = [[musicID]]

        recordEntity.properties = [
            id, startedAt, listenedDurationMs,
            completionRate, isCompleted, isSkipped,
            moodRawValue, recordToMusic
        ]

        model.entities = [musicEntity, recordEntity]
        return model
    }()
}
