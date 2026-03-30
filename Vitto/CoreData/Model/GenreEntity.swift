import CoreData
import MusicKit

class GenreEntity: NSManagedObject {
    @NSManaged var genreID: String?
    @NSManaged var name: String?
    @NSManaged var cachedAt: Date?
}

// MARK: - Convenience

extension GenreEntity {

    /// 장르명으로 기존 엔티티를 찾거나 없으면 새로 생성
    func toGenreInfo() -> GenreInfo? {
        guard let id = genreID, let name = name else { return nil }
        return GenreInfo(id: MusicItemID(id), name: name)
    }

    static func findOrCreate(
        name: String,
        in context: NSManagedObjectContext
    ) -> GenreEntity {
        let request = NSFetchRequest<GenreEntity>(entityName: "GenreEntity")
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let entity = GenreEntity(
            entity: NSEntityDescription.entity(forEntityName: "GenreEntity", in: context)!,
            insertInto: context
        )
        entity.name = name
        entity.cachedAt = Date()
        return entity
    }
}
