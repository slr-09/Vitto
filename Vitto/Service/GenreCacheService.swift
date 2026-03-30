import CoreData
import RxSwift
import MusicKit

final class GenreCacheService {

    static let shared = GenreCacheService()
    private init() {}

    private let stack = CoreDataStack.shared
    private let musicSearchService = MusicSearchService.shared

    /// 캐시 유효 기간 (7일)
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60

    // MARK: - Public

    /// 캐시된 장르명 목록을 반환. 캐시가 없거나 만료되면 API에서 새로 가져옴
    func cachedGenreNames() -> Observable<[String]> {
        let cached = fetchCachedGenres()

        if !cached.isEmpty, isCacheValid(cached) {
            return .just(cached.compactMap { $0.name })
        }

        return refreshGenres()
            .map { [weak self] _ in
                self?.fetchCachedGenres().compactMap { $0.name } ?? []
            }
    }

    /// Apple Music API에서 장르 목록을 가져와 CoreData에 저장
    func refreshGenres() -> Observable<Void> {
        musicSearchService.fetchGenres()
            .map { [weak self] genres in
                self?.saveGenres(genres)
            }
    }

    // MARK: - Private

    private func fetchCachedGenres() -> [GenreEntity] {
        let request = NSFetchRequest<GenreEntity>(entityName: "GenreEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? stack.context.fetch(request)) ?? []
    }

    private func isCacheValid(_ genres: [GenreEntity]) -> Bool {
        guard let cachedAt = genres.first?.cachedAt else { return false }
        return DateManager.shared.isWithinTTL(cachedAt, ttl: cacheTTL)
    }

    /// 장르 저장
    private func saveGenres(_ genres: [Genre]) {
        let ctx = stack.context
        let now = Date()

        for genre in genres {
            let entity = GenreEntity.findOrCreate(name: genre.name, in: ctx)
            entity.genreID = genre.id.rawValue
            entity.cachedAt = now
        }

        stack.saveContext()
        print("[GenreCacheService] 장르 캐시 저장 완료: \(genres.count)개")
    }
}
