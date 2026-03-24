import CoreData
import RxSwift

final class PlaybackRecordService {

    static let shared = PlaybackRecordService()

    private let stack = CoreDataStack.shared
    private init() {}

    // MARK: - 기록 생성/종료

    /// 재생 시작 시 호출 — PlaybackRecord를 생성하고 반환
    func startRecord(music: Music, mood: MoodType) -> PlaybackRecord {
        let ctx = stack.context
        let musicEntity = MusicEntity.findOrCreate(from: music, in: ctx)

        let record = PlaybackRecord(
            entity: NSEntityDescription.entity(forEntityName: "PlaybackRecord", in: ctx)!,
            insertInto: ctx
        )
        record.id = UUID()
        record.music = musicEntity
        record.startedAt = Date()
        record.moodRawValue = mood.rawValue

        stack.saveContext()
        return record
    }

    /// 재생 종료 시 호출 — 완청률, 스킵 여부 계산 후 저장
    func endRecord(_ record: PlaybackRecord, listenedMs: Int, totalMs: Int) {
        record.listenedDurationMs = Int32(listenedMs)

        let rate = totalMs > 0 ? Float(listenedMs) / Float(totalMs) : 0
        record.completionRate = min(rate, 1.0)
        record.isCompleted = rate >= 0.9
        record.isSkipped = listenedMs < 30_000

        stack.saveContext()
    }

    // MARK: - 쿼리: 무드 기반

    /// 특정 무드에서 스킵하지 않고 들은 곡 조회
    func songs(forMood mood: MoodType) -> Observable<[Music]> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let ctx = self.stack.context
            let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
            request.predicate = NSPredicate(
                format: "moodRawValue == %@ AND isSkipped == NO",
                mood.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]

            do {
                let records = try ctx.fetch(request)
                let uniqueSongs = self.uniqueSongs(from: records)
                observer.onNext(uniqueSongs)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - 쿼리: 가장 많이 들은 곡

    /// 완청 횟수 기준 상위 곡 (반복 재생 탐지)
    func mostPlayedSongs(limit: Int = 20) -> Observable<[(music: Music, playCount: Int)]> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let ctx = self.stack.context
            let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
            request.predicate = NSPredicate(format: "isSkipped == NO")

            do {
                let records = try ctx.fetch(request)

                // musicID별 그룹핑 후 카운트
                var countMap: [String: (music: Music, count: Int)] = [:]
                for record in records {
                    guard let entity = record.music, let id = entity.musicID else { continue }
                    if let existing = countMap[id] {
                        countMap[id] = (existing.music, existing.count + 1)
                    } else {
                        countMap[id] = (entity.toMusic(), 1)
                    }
                }

                let sorted = countMap.values
                    .sorted { $0.count > $1.count }
                    .prefix(limit)
                    .map { (music: $0.music, playCount: $0.count) }

                observer.onNext(Array(sorted))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - 쿼리: 장르별 선호도

    /// 완청률이 높은 상위 장르 목록
    func topGenres(limit: Int = 10) -> Observable<[(genre: String, avgCompletionRate: Float, playCount: Int)]> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let ctx = self.stack.context
            let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
            request.predicate = NSPredicate(format: "isSkipped == NO")

            do {
                let records = try ctx.fetch(request)

                var genreStats: [String: (totalRate: Float, count: Int)] = [:]
                for record in records {
                    guard let genre = record.music?.genre, !genre.isEmpty else { continue }
                    let existing = genreStats[genre] ?? (0, 0)
                    genreStats[genre] = (existing.totalRate + record.completionRate, existing.count + 1)
                }

                let sorted = genreStats
                    .map { (genre: $0.key, avgCompletionRate: $0.value.totalRate / Float($0.value.count), playCount: $0.value.count) }
                    .sorted { $0.playCount > $1.playCount }
                    .prefix(limit)

                observer.onNext(Array(sorted))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Private Helpers

    /// PlaybackRecord 배열에서 중복 없는 Music 배열 추출
    private func uniqueSongs(from records: [PlaybackRecord]) -> [Music] {
        var seen = Set<String>()
        var result: [Music] = []
        for record in records {
            guard let entity = record.music, let id = entity.musicID, !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(entity.toMusic())
        }
        return result
    }
}
